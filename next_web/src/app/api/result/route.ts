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
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
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
const resultRateLimit = new Map<string, { count: number; resetAt: number }>();
const RATE_WINDOW = 60_000;
const RATE_MAX = 10;

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = resultRateLimit.get(ip);
  if (!entry || now > entry.resetAt) {
    resultRateLimit.set(ip, { count: 1, resetAt: now + RATE_WINDOW });
    return true;
  }
  if (entry.count >= RATE_MAX) return false;
  entry.count++;
  return true;
}

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
      origin
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

    // 2. Look up student
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

    // 3. Get level info to calculate percentage and max points
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
