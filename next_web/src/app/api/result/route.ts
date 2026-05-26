import { NextResponse } from 'next/server';
import { getAdminClient } from '@/lib/supabase-admin';
import { getCorsHeaders, jsonResponse, optionsResponse, checkRateLimit, getClientIp } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const supabase = getAdminClient();
    const { data: settings, error: settingsError } = await supabase
      .from('app_settings')
      .select('is_result_query_open')
      .eq('id', 1)
      .maybeSingle();

    if (settingsError) {
      console.error('Settings error:', settingsError);
      return jsonResponse({ error: 'حدث خطأ في قراءة الإعدادات' }, 500, origin);
    }

    return jsonResponse(
      {
        success: true,
        is_result_query_open: !!settings?.is_result_query_open,
      },
      200,
      origin,
      60
    );
  } catch (error: unknown) {
    console.error('Result GET Error:', error);
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}

export async function POST(request: Request) {
  const origin = request.headers.get('origin');

  try {
    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 10)) {
      return jsonResponse(
        { error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' },
        429,
        origin
      );
    }

    const body = await request.json();
    const { nationalId } = body;

    if (!nationalId || String(nationalId).length !== 14) {
      return jsonResponse(
        { error: 'الرقم القومي يجب أن يتكون من 14 رقماً' },
        400,
        origin
      );
    }

    const supabase = getAdminClient();

    // 1. Check if result query is open
    const { data: settings, error: settingsError } = await supabase
      .from('app_settings')
      .select('is_result_query_open')
      .eq('id', 1)
      .maybeSingle();

    if (settingsError) {
      console.error('Settings error:', settingsError);
      return jsonResponse({ error: 'حدث خطأ في قراءة الإعدادات' }, 500, origin);
    }

    if (!settings?.is_result_query_open) {
      return jsonResponse(
        {
          error:
            'قسم الاستعلام عن النتيجة النهائية غير متاح حالياً. يُرجى المتابعة مع الإدارة.',
          closed: true,
        },
        403,
        origin
      );
    }

    // 2. Look up student + level info in parallel
    const { data: student, error: studentError } = await supabase
      .from('students')
      .select(
        'id, name, gender, level, student_code, score, rewaya_score, tajweed_score, voice_score, meaning_score, profile_image_url, national_id, selected_rewaya'
      )
      .eq('national_id', String(nationalId))
      .maybeSingle();

    if (studentError) {
      console.error('Student fetch error:', studentError);
      return jsonResponse(
        { error: 'حدث خطأ في قاعدة البيانات أثناء البحث' },
        500,
        origin
      );
    }

    if (!student) {
      return jsonResponse(
        {
          error:
            'لم يُعثر على متسابق بهذا الرقم القومي. تأكد من الرقم المُدخل أو تواصل مع الإدارة.',
        },
        404,
        origin
      );
    }

    // 3. Get level info (fetched only when student exists)
    const { data: levelData } = await supabase
      .from('competition_levels')
      .select('content, total_points, has_rewaya, rewaya_max_score, has_tajweed, tajweed_max_score, has_voice, voice_max_score, has_meaning, meaning_max_score')
      .eq('title', student.level)
      .maybeSingle();

    return jsonResponse(
      {
        success: true,
        student: {
          id: student.id,
          name: student.name,
          gender: student.gender,
          level: student.level,
          level_content: levelData?.content || '',
          student_code: student.student_code,
          profile_image_url: student.profile_image_url,
          score: student.score,
          rewaya_score: student.rewaya_score,
          selected_rewaya: student.selected_rewaya,
          tajweed_score: student.tajweed_score,
          voice_score: student.voice_score,
          meaning_score: student.meaning_score,
        },
        level: levelData,
      },
      200,
      origin
    );
  } catch (error: unknown) {
    console.error('Result API Error:', error);
    const message =
      error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
