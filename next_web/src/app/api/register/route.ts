import { NextResponse } from 'next/server';
import { getAdminClient } from '@/lib/supabase-admin';
import { getCorsHeaders, jsonResponse, optionsResponse, checkRateLimit, getClientIp, validateCsrf } from '@/lib/api-utils';
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

    if (body.website_url_verification) {
      return jsonResponse({
        success: true,
        message: 'تم التسجيل بنجاح'
      }, 200, origin);
    }

    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 5)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' }, 429, origin);
    }

    // Layer 2: Database-backed rate limiter (global block across all serverless nodes)
    if (ip !== 'unknown') {
      const oneMinuteAgo = new Date(Date.now() - 60_000).toISOString();
      const { count, error: limitErr } = await supabase
        .from('students')
        .select('id', { count: 'exact', head: true })
        .eq('registration_ip', ip)
        .gte('created_at', oneMinuteAgo);

      if (!limitErr && count !== null && count >= 5) {
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
    if (body.memorizer_phone && body.memorizer_phone.trim().length > 15) {
      return jsonResponse({ error: 'رقم هاتف المحفظ طويل جداً' }, 400, origin);
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

    // Validate age and gender against national ID
    if (nationalId) {
      const idInfo = parseNationalId(nationalId);
      if (!idInfo) {
        return jsonResponse({ error: 'الرقم القومي غير صالح' }, 400, origin);
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
    const studentData = {
      name,
      phone,
      national_id: nationalId || null,
      level,
      age,
      gender: gender || null,
      profile_image_url: body.profile_image_url || null,
      birth_certificate_url: body.birth_certificate_url || null,
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
      .select('min_age, max_age, max_capacity, branches, has_rewaya, available_rewayas')
      .eq('title', studentData.level)
      .eq('is_active', true)
      .single();

    if (!levelData) {
      return jsonResponse({ error: 'المستوى المحدد غير موجود أو غير نشط' }, 400, origin);
    }

    if (studentData.age != null) {
      if (levelData.min_age != null && studentData.age <= levelData.min_age) {
        return jsonResponse({ error: `عمرك أقل من الحد الأدنى المطلوب لهذا المستوى (${levelData.min_age} سنة)` }, 400, origin);
      }
      if (levelData.max_age != null && studentData.age > levelData.max_age) {
        return jsonResponse({ error: `عمرك أكبر من الحد الأقصى المطلوب لهذا المستوى (${levelData.max_age} سنة)` }, 400, origin);
      }
    }

    // 4.1 Check Selected Level Capacity
    if (levelData.max_capacity !== null) {
      const { count } = await supabase
        .from('students')
        .select('id', { count: 'exact', head: true })
        .eq('level', studentData.level);

      if (count !== null && count >= levelData.max_capacity) {
        return jsonResponse({ error: 'عذراً، هذا المستوى ممتلئ تماماً ولا يمكن قبول تسجيلات جديدة فيه.' }, 400, origin);
      }
    }

    // 4.2 Validate rewaya
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

    // 4.6 Check Active Exam Schedule Capacity
    const { data: settings } = await supabase
      .from('app_settings')
      .select('exam_schedule')
      .eq('id', 1)
      .single();

    if (settings && settings.exam_schedule && Array.isArray(settings.exam_schedule)) {
      let totalCap = 0;
      for (const slot of settings.exam_schedule as Array<Record<string, unknown>>) {
        const s = (slot.start_hour as number) || 8;
        const e = (slot.end_hour as number) || 13;
        const cap = (slot.students_per_hour as number) || 4;
        totalCap += (e - s) * cap;
      }

      if (totalCap > 0) {
        const { count: totalStudents } = await supabase
          .from('students')
          .select('id', { count: 'exact', head: true });

        if (totalStudents !== null && totalStudents >= totalCap) {
          return jsonResponse({ error: 'عذراً، لقد اكتملت جميع المواعيد المتاحة حالياً. تم إغلاق التسجيل مؤقتاً لحين توفر مواعيد جديدة.' }, 400, origin);
        }
      }
    }

    // 5. Final Insert
    const { data: newStudent, error: insertErr } = await supabase
      .from('students')
      .insert(studentData)
      .select('id, student_code, name, level, age, profile_image_url, birth_certificate_url, exam_date, exam_hour')
      .single();

    if (insertErr) {
      if (insertErr.code === '23505') {
        return jsonResponse({ error: 'الرقم القومي مسجل مسبقاً، أو يوجد حقل آخر يتطلب قيمة فريدة.' }, 409, origin);
      }
      if (insertErr.code === '23514') {
        return jsonResponse({ error: 'بيانات غير صالحة. تحقق من الحقول.' }, 400, origin);
      }
      return jsonResponse({ error: insertErr.message }, 500, origin);
    }

    // Re-fetch the student to ensure we get trigger-assigned values (exam_date, exam_hour, student_code)
    const { data: fetchedStudent } = await supabase
      .from('students')
      .select('id, student_code, name, level, age, profile_image_url, birth_certificate_url, exam_date, exam_hour')
      .eq('id', newStudent!.id)
      .single();

    const finalStudent = fetchedStudent ?? newStudent;

    return jsonResponse({ success: true, data: finalStudent }, 200, origin);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
