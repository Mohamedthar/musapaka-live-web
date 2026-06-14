import { getAdminClient } from '@/lib/supabase-admin';
import { jsonResponse, optionsResponse, checkRateLimit, getClientIp, validateCsrf } from '@/lib/api-utils';
import { parseNationalId, calculateAgeFromNationalId } from '@/lib/national-id';

export { optionsResponse as OPTIONS };

export async function POST(request: Request) {
  const origin = request.headers.get('origin');
  try {
    if (!validateCsrf(request)) {
      return jsonResponse({ error: 'طلب غير مصرح به' }, 403, origin);
    }

    const body = await request.json();
    const token = body.token;
    const supabase = getAdminClient();

    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 15)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' }, 429, origin);
    }

    // Honeypot trap — moved after rate limit so attackers still get rate-limited
    if (body.website_url_verification) {
      await new Promise(r => setTimeout(r, 2000));
      return jsonResponse({ success: true, message: 'تم التسجيل بنجاح' }, 200, origin);
    }

    // Layer 2: Database-backed rate limiter (global block across all serverless nodes)
    if (ip !== 'unknown') {
      const oneMinuteAgo = new Date(Date.now() - 60_000).toISOString();
      const { count, error: limitErr } = await supabase
        .from('students')
        .select('id', { count: 'exact', head: true })
        .eq('registration_ip', ip)
        .gte('created_at', oneMinuteAgo);

      if (!limitErr && count !== null && count >= 10) {
        return jsonResponse({ error: 'طلبات كثيرة جداً من هذا الجهاز. حاول بعد دقيقة.' }, 429, origin);
      }
    }

    // 2. Verify Turnstile Token
    if (process.env.NODE_ENV !== 'development' && process.env.SKIP_TURNSTILE !== 'true') {
      if (!token) {
        return jsonResponse({ error: 'رمز التحقق مطلوب' }, 400, origin);
      }

      const verifyRes = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          secret: process.env.TURNSTILE_SECRET_KEY,
          response: token,
        }),
      });

      const verifyData = await verifyRes.json();
      if (!verifyData.success) {
        return jsonResponse({ error: 'فشل التحقق من أمان المتصفح.' }, 400, origin);
      }
    }

    // 2. Validate input fields
    const name = body.name?.trim();
    const phone = body.phone?.trim();
    const age = body.age;
    const nationalId = body.national_id?.trim();
    const level = body.level;
    const gender = body.gender;
    const memorizerName = body.memorizer_name?.trim();
    const selectedRewaya = body.selected_rewaya?.trim() || null;

    if (!name || name.length < 10) {
      return jsonResponse({ error: 'الاسم يجب أن يتكون من 4 أسماء على الأقل' }, 400, origin);
    }
    if (name.length > 100) {
      return jsonResponse({ error: 'الاسم طويل جداً (الحد الأقصى 100 حرف)' }, 400, origin);
    }
    if (!phone || !/^(010|011|012|015)\d{8}$/.test(phone)) {
      return jsonResponse({ error: 'رقم الهاتف المصري غير صحيح' }, 400, origin);
    }
    if (phone.length > 15) {
      return jsonResponse({ error: 'رقم الهاتف طويل جداً' }, 400, origin);
    }
    if (age == null || typeof age !== 'number' || age < 5 || age > 100) {
      return jsonResponse({ error: 'العمر يجب أن يكون بين 5 و 100' }, 400, origin);
    }
    if (!level) {
      return jsonResponse({ error: 'المستوى مطلوب' }, 400, origin);
    }
    if (!memorizerName) {
      return jsonResponse({ error: 'اسم المحفِّظ مطلوب' }, 400, origin);
    }
    if (memorizerName.length > 100) {
      return jsonResponse({ error: 'اسم المحفِّظ طويل جداً (الحد الأقصى 100 حرف)' }, 400, origin);
    }
    if (body.memorizer_phone) {
      const mp = body.memorizer_phone.trim();
      if (mp.length > 15) {
        return jsonResponse({ error: 'رقم هاتف المحفظ طويل جداً' }, 400, origin);
      }
      if (mp.length > 0 && !/^(010|011|012|015)\d{8}$/.test(mp)) {
        return jsonResponse({ error: 'رقم هاتف المحفظ المصري غير صحيح (يجب أن يبدأ بـ 010 أو 011 أو 012 أو 015)' }, 400, origin);
      }
    }
    if (phone && body.memorizer_phone && phone.trim() === body.memorizer_phone.trim()) {
      return jsonResponse({ error: 'رقم هاتف الطالب يجب أن يكون مختلفاً عن رقم هاتف المحفظ' }, 400, origin);
    }
    if (body.memorizer_address && body.memorizer_address.trim().length > 200) {
      return jsonResponse({ error: 'عنوان المحفظ طويل جداً (الحد الأقصى 200 حرف)' }, 400, origin);
    }
    if (body.location && body.location.trim().length > 200) {
      return jsonResponse({ error: 'العنوان طويل جداً (الحد الأقصى 200 حرف)' }, 400, origin);
    }
    if (nationalId && !/^\d{14}$/.test(nationalId)) {
      return jsonResponse({ error: 'الرقم القومي يجب أن يكون 14 رقماً' }, 400, origin);
    }
    if (gender && !['ذكر', 'أنثى'].includes(gender)) {
      return jsonResponse({ error: 'النوع غير صحيح' }, 400, origin);
    }

    // Validate age, birth_date, and gender against national ID
    if (nationalId) {
      const idInfo = parseNationalId(nationalId);
      if (!idInfo) {
        return jsonResponse({ error: 'الرقم القومي غير صالح' }, 400, origin);
      }

      if (body.birth_date && body.birth_date !== idInfo.birthDate) {
        return jsonResponse({ error: 'تاريخ الميلاد او الرقم القومي غير صحيحين' }, 400, origin);
      }

      const idAge = calculateAgeFromNationalId(nationalId);
      if (idAge !== null && age !== idAge) {
        return jsonResponse({ error: 'العمر غير صحيح' }, 400, origin);
      }

      const idGender = idInfo.gender;
      if (gender && gender !== idGender) {
        return jsonResponse({ error: 'النوع غير صحيح' }, 400, origin);
      }
    }

    // 3. Sanitize and Extract Data (Security: Prevent Mass Assignment)
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const profileUrl = body.profile_image_url || null;
    const birthCertUrl = body.birth_certificate_url || null;

    if (!profileUrl || !birthCertUrl) {
      return jsonResponse({ error: 'الصورة الشخصية وشهادة الميلاد مطلوبتان' }, 400, origin);
    }

    if (cloudName) {
      const validCloudUrl = (url: string) =>
        url.startsWith(`https://res.cloudinary.com/${cloudName}/`) ||
        url.startsWith(`https://res-console.cloudinary.com/${cloudName}/`);
      if (!validCloudUrl(profileUrl)) {
        return jsonResponse({ error: 'رابط الصورة الشخصية غير صالح' }, 400, origin);
      }
      if (!validCloudUrl(birthCertUrl)) {
        return jsonResponse({ error: 'رابط شهادة الميلاد غير صالح' }, 400, origin);
      }
    }

    const studentData = {
      name,
      phone,
      national_id: nationalId || null,
      level,
      age,
      gender: gender || null,
      profile_image_url: profileUrl,
      birth_certificate_url: birthCertUrl,
      memorizer_name: memorizerName,
      memorizer_phone: body.memorizer_phone?.trim() || null,
      memorizer_address: body.memorizer_address?.trim() || null,
      location: body.location?.trim() || null,
      birth_date: body.birth_date || null,
      selected_rewaya: selectedRewaya,
      registration_ip: ip,
      branch_name: body.branch_name?.trim() || null,
      memorization_amount: body.memorization_amount ?? null,
    };

    // 3. Check for duplicate name or national ID
    // Phone is NOT checked for duplicates — siblings may share a parent's phone
    const [dupName, dupId] = await Promise.all([
      supabase.from('students').select('id').eq('name', name).maybeSingle(),
      nationalId
        ? supabase.from('students').select('id').eq('national_id', nationalId).maybeSingle()
        : Promise.resolve({ data: null, error: null }),
    ]);

    if (dupName.data) {
      return jsonResponse({ error: 'هذا الاسم مسجل مسبقاً في النظام' }, 409, origin);
    }
    if (dupId.data) {
      return jsonResponse({ error: 'هذا الرقم القومي مسجل مسبقاً في النظام' }, 409, origin);
    }

    // 4. Check Selected Level Age & Capacity Restrictions
    const { data: levelData } = await supabase
      .from('competition_levels')
      .select('min_age, max_age, max_capacity, branches, has_rewaya, available_rewayas, age_op')
      .eq('title', studentData.level)
      .eq('is_active', true)
      .single();

    if (!levelData) {
      return jsonResponse({ error: 'المستوى المحدد غير موجود أو غير نشط' }, 400, origin);
    }

    if (studentData.age != null) {
      const op = (levelData as Record<string, unknown>).age_op as string | undefined;
      if (op === 'gt' && levelData.min_age != null && studentData.age <= levelData.min_age) {
        return jsonResponse({ error: `يجب أن يكون العمر أكبر من ${levelData.min_age} سنة لهذا المستوى` }, 400, origin);
      }
      if (op === 'gte' && levelData.min_age != null && studentData.age < levelData.min_age) {
        return jsonResponse({ error: `الحد الأدنى للعمر ${levelData.min_age} سنة لهذا المستوى` }, 400, origin);
      }
      if (op === 'lt' && levelData.max_age != null && studentData.age >= levelData.max_age) {
        return jsonResponse({ error: `يجب أن يكون العمر أقل من ${levelData.max_age} سنة لهذا المستوى` }, 400, origin);
      }
      if (op === 'lte' && levelData.max_age != null && studentData.age > levelData.max_age) {
        return jsonResponse({ error: `الحد الأقصى للعمر ${levelData.max_age} سنة لهذا المستوى` }, 400, origin);
      }
      if (op === 'range') {
        if (levelData.min_age != null && studentData.age < levelData.min_age) {
          return jsonResponse({ error: `عمرك أقل من الحد الأدنى المطلوب لهذا المستوى (${levelData.min_age} سنة)` }, 400, origin);
        }
        if (levelData.max_age != null && studentData.age > levelData.max_age) {
          return jsonResponse({ error: `عمرك أكبر من الحد الأقصى المطلوب لهذا المستوى (${levelData.max_age} سنة)` }, 400, origin);
        }
      }
      // fallback: بدون age_op
      if (!op || op === 'gte' || op === 'range') {
        // already handled above for gte/range
      }
      if (!op) {
        if (levelData.min_age != null && studentData.age < levelData.min_age) {
          return jsonResponse({ error: `عمرك أقل من الحد الأدنى المطلوب لهذا المستوى (${levelData.min_age} سنة)` }, 400, origin);
        }
        if (levelData.max_age != null && studentData.age > levelData.max_age) {
          return jsonResponse({ error: `عمرك أكبر من الحد الأقصى المطلوب لهذا المستوى (${levelData.max_age} سنة)` }, 400, origin);
        }
      }
    }

    // 4.1 Validate rewaya
    if (studentData.selected_rewaya) {
      if (!levelData.has_rewaya) {
        return jsonResponse({ error: 'هذا المستوى لا يدعم اختيار الروايات' }, 400, origin);
      }
      const available = (levelData.available_rewayas as string[]) || [];
      if (available.length && !available.includes(studentData.selected_rewaya)) {
        return jsonResponse({ error: 'الرواية المختارة غير متاحة لهذا المستوى' }, 400, origin);
      }
    }

    // 4.3 Validate branch
    if (studentData.branch_name) {
      const branches = (levelData.branches as string[]) || [];
      if (branches.length && !branches.includes(studentData.branch_name.trim())) {
        return jsonResponse({ error: 'الفرع المختار غير متاح لهذا المستوى' }, 400, origin);
      }
    }

    // 5. Final Insert — database triggers handle capacity & scheduling
    const { data: newStudent, error: insertErr } = await supabase
      .from('students')
      .insert(studentData)
      .select('id, student_code, name, level, age, profile_image_url, birth_certificate_url, exam_date, exam_hour')
      .single();

    // NOTE: There is a TOCTOU race condition between the duplicate check (lines 181–193)
    // and this insert. Two concurrent requests with the same name/national_id/phone can
    // both pass the SELECT checks before either INSERT executes. The database UNIQUE
    // constraint (23505) is the final defense — we inspect which constraint was violated
    // to return a precise error message.
    if (insertErr) {
      if (insertErr.code === '23505') {
        const detail = (insertErr as { details?: string }).details || (insertErr as { detail?: string })?.detail || '';
        if (detail.includes('students_name') || detail.includes('name')) {
          return jsonResponse({ error: 'هذا الاسم مسجل مسبقاً في النظام' }, 409, origin);
        }
        if (detail.includes('national_id')) {
          return jsonResponse({ error: 'هذا الرقم القومي مسجل مسبقاً في النظام' }, 409, origin);
        }
        return jsonResponse({ error: 'بيانات مكررة. قد يكون الاسم أو الرقم القومي مسجلاً مسبقاً.' }, 409, origin);
      }
      if (insertErr.code === '23514') {
        return jsonResponse({ error: 'بيانات غير صالحة. تحقق من الحقول.' }, 400, origin);
      }
      // Catch trigger-raised exceptions (exam slots full, capacity full, etc.)
      const errMsg = (insertErr as { message?: string }).message || '';
      if (errMsg.includes('اكتملت جميع المواعيد')) {
        return jsonResponse({ error: errMsg }, 409, origin);
      }
      if (errMsg.includes('ممتلئ')) {
        return jsonResponse({ error: errMsg }, 409, origin);
      }
      return jsonResponse({ error: 'حدث خطأ أثناء التسجيل. يرجى المحاولة مرة أخرى.' }, 500, origin);
    }

    return jsonResponse({ success: true, data: newStudent }, 200, origin);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
