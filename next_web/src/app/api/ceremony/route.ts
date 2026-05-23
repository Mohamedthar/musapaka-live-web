import { NextResponse } from 'next/server';
import { getAdminClient } from '@/lib/supabase-admin';

const ALLOWED_ORIGINS = [
  process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000',
  'https://musapaka.vercel.app',
].filter(Boolean);

function getCorsHeaders(origin: string | null) {
  const allowedOrigin =
    origin && ALLOWED_ORIGINS.includes(origin)
      ? origin
      : ALLOWED_ORIGINS[0] || '';
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    Vary: 'Origin',
  };
}

function jsonResponse(
  data: unknown,
  status = 200,
  requestOrigin: string | null = null
) {
  return NextResponse.json(data, {
    status,
    headers: getCorsHeaders(requestOrigin ?? null),
  });
}

export async function OPTIONS(request: Request) {
  const origin = request.headers.get('origin');
  return new NextResponse(null, { status: 204, headers: getCorsHeaders(origin) });
}

// Rate limiting
const ceremonyRateLimit = new Map<string, { count: number; resetAt: number }>();
const RATE_WINDOW = 60_000;
const RATE_MAX = 10;

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = ceremonyRateLimit.get(ip);
  if (!entry || now > entry.resetAt) {
    ceremonyRateLimit.set(ip, { count: 1, resetAt: now + RATE_WINDOW });
    return true;
  }
  if (entry.count >= RATE_MAX) return false;
  entry.count++;
  return true;
}

export async function POST(request: Request) {
  const origin = request.headers.get('origin');

  try {
    const ip =
      request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      'unknown';
    if (!checkRateLimit(ip)) {
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
            'لم يُعثر على متسابق بهذا الرقم القومي. تأكد من الرقم المُدخل أو تواصل مع الإدارة.',
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
      if (levelData.has_rewaya) maxScore += levelData.rewaya_max_score ?? 100;
      if (levelData.has_tajweed) maxScore += levelData.tajweed_max_score ?? 100;
      if (levelData.has_voice) maxScore += levelData.voice_max_score ?? 100;
      if (levelData.has_meaning) maxScore += levelData.meaning_max_score ?? 100;
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
