import { getPublicClient } from '@/lib/supabase-public';
import { jsonResponse, optionsResponse, checkRateLimit, getClientIp, validateCsrf } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function POST(request: Request) {
  const origin = request.headers.get('origin');
  try {
    if (!validateCsrf(request)) {
      return jsonResponse({ error: 'طلب غير مصرح به' }, 403, origin);
    }
    const body = await request.json();
    const { nationalId } = body;

    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 10)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' }, 429, origin);
    }

    if (!nationalId || nationalId.length !== 14) {
      return jsonResponse({ error: 'الرقم القومي يجب أن يتكون من 14 رقماً' }, 400, origin);
    }

    const supabase = getPublicClient();

    const [studentRes, levelsRes] = await Promise.all([
      supabase.rpc('public_lookup_student', { p_national_id: nationalId }),
      supabase
        .from('competition_levels')
        .select('id, title, content, is_active, total_points, has_rewaya, rewaya_max_score, has_tajweed, tajweed_max_score, has_voice, voice_max_score, has_meaning, meaning_max_score')
        .eq('is_active', true)
    ]);

    const { data: studentData, error: studentError } = studentRes;
    const { data: levels } = levelsRes;

    if (studentError) {
      return jsonResponse({ error: 'حدث خطأ في قاعدة البيانات أثناء البحث' }, 500, origin);
    }

    const student = Array.isArray(studentData) ? studentData[0] : studentData;
    if (!student) {
      return jsonResponse({ error: 'لم يُعثر على متسابق بهذا الرقم القومي. تأكد من البيانات المُدخلة أو تواصل مع الإدارة.' }, 404, origin);
    }

    return jsonResponse({
      success: true,
      student,
      levels: levels || [],
    }, 200, origin);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
