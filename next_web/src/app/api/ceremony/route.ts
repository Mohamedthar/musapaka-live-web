import { NextResponse } from 'next/server';
import { getAdminClient } from '@/lib/supabase-admin';
import { getCorsHeaders, jsonResponse, optionsResponse, checkRateLimit, getClientIp } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const supabase = getAdminClient();
    const { data: settings, error } = await supabase
      .from('app_settings')
      .select('is_ceremony_query_open')
      .eq('id', 1)
      .maybeSingle();

    if (error) {
      return jsonResponse({ error: 'حدث خطأ في قراءة الإعدادات' }, 500, origin);
    }

    return jsonResponse({
      is_ceremony_query_open: !!settings?.is_ceremony_query_open,
    }, 200, origin, 60);
  } catch (error: unknown) {
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

    // 1. Check if ceremony query is open
    const { data: settings, error: settingsError } = await supabase
      .from('app_settings')
      .select('is_ceremony_query_open')
      .eq('id', 1)
      .maybeSingle();

    if (settingsError) {
      console.error('Settings error:', settingsError);
      return jsonResponse({ error: 'حدث خطأ في قراءة الإعدادات' }, 500, origin);
    }

    if (!settings?.is_ceremony_query_open) {
      return jsonResponse(
        {
          error:
            'قسم الاستعلام عن حضور الحفل غير متاح حالياً. يُرجى المتابعة مع الإدارة.',
          closed: true,
        },
        403,
        origin
      );
    }

    // 2. Look up student
    const { data: student, error: studentError } = await supabase
      .from('students')
      .select(
        'id, name, gender, level, student_code, ceremony_code, score, rewaya_score, tajweed_score, voice_score, meaning_score, profile_image_url, national_id'
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
            'لم يُعثر على متسابق بهذا الرقم القومي. تأكد من البيانات المُدخلة أو تواصل مع الإدارة.',
        },
        404,
        origin
      );
    }

    // 3. Get level info to calculate percentage
    const { data: levelData } = await supabase
      .from('competition_levels')
      .select('content, total_points, has_rewaya, rewaya_max_score, has_tajweed, tajweed_max_score, has_voice, voice_max_score, has_meaning, meaning_max_score')
      .eq('title', student.level)
      .maybeSingle();

    let maxScore = levelData?.total_points ?? 100;
    if (levelData) {
      if (levelData.has_rewaya && (levelData.rewaya_max_score ?? 0) > 0) maxScore += levelData.rewaya_max_score ?? 0;
      if (levelData.has_tajweed && (levelData.tajweed_max_score ?? 0) > 0) maxScore += levelData.tajweed_max_score ?? 0;
      if (levelData.has_voice && (levelData.voice_max_score ?? 0) > 0) maxScore += levelData.voice_max_score ?? 0;
      if (levelData.has_meaning && (levelData.meaning_max_score ?? 0) > 0) maxScore += levelData.meaning_max_score ?? 0;
    }

    const totalScore =
      (student.score ?? 0) +
      (student.rewaya_score ?? 0) +
      (student.tajweed_score ?? 0) +
      (student.voice_score ?? 0) +
      (student.meaning_score ?? 0);

    const percentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0;
    const isEligible = percentage >= 95;

    return jsonResponse(
      {
        success: true,
        student: {
          name: student.name,
          gender: student.gender,
          level: student.level,
          level_content: levelData?.content || '',
          ceremony_code: student.ceremony_code,
          profile_image_url: student.profile_image_url,
          is_eligible: isEligible,
        },
      },
      200,
      origin
    );
  } catch (error: unknown) {
    console.error('Ceremony API Error:', error);
    const message =
      error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
