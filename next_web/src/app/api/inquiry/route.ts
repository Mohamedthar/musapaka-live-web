import { NextResponse } from 'next/server';
import { getAdminClient } from '@/lib/supabase-admin';
import { getCorsHeaders, jsonResponse, optionsResponse, checkRateLimit, getClientIp } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function POST(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const body = await request.json();
    const { nationalId } = body;

    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 10)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' }, 429, origin);
    }

    if (!nationalId || nationalId.length !== 14) {
      return jsonResponse({ error: 'الرقم القومي يجب أن يتكون من 14 رقماً' }, 400, origin);
    }

    const supabase = getAdminClient();

    const [studentRes, levelsRes] = await Promise.all([
      supabase
        .from('students')
        .select('id, student_code, name, phone, national_id, age, gender, level, selected_rewaya, branch_name, memorization_amount, memorizer_name, memorizer_phone, memorizer_address, location, birth_date, score, rewaya_score, tajweed_score, voice_score, meaning_score, profile_image_url, birth_certificate_url, exam_date, exam_hour, notes, created_at')
        .eq('national_id', nationalId)
        .maybeSingle(),
      supabase
        .from('competition_levels')
        .select('id, title, content, is_active, total_points, has_rewaya, rewaya_max_score, has_tajweed, tajweed_max_score, has_voice, voice_max_score, has_meaning, meaning_max_score')
        .eq('is_active', true)
    ]);

    const { data: student, error: studentError } = studentRes;
    const { data: levels, error: levelsError } = levelsRes;

    if (studentError) {
      console.error('Database error fetching student:', studentError);
      return jsonResponse({ error: 'حدث خطأ في قاعدة البيانات أثناء البحث' }, 500, origin);
    }

    if (!student) {
      return jsonResponse({ error: 'لم يُعثر على متسابق بهذا الرقم القومي. تأكد من البيانات المُدخلة أو تواصل مع الإدارة.' }, 404, origin);
    }

    if (levelsError) {
      console.error('Database error fetching levels:', levelsError);
    }

    return jsonResponse({
      success: true,
      student,
      levels: levels || [],
    }, 200, origin);
  } catch (error: unknown) {
    console.error('Inquiry API Error:', error);
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
