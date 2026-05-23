import { NextResponse } from 'next/server';
import { getAdminClient } from '@/lib/supabase-admin';

const ALLOWED_ORIGINS = [
  process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000',
  'https://musapaka.vercel.app',
].filter(Boolean);

function getCorsHeaders(origin: string | null) {
  const allowedOrigin = (origin && ALLOWED_ORIGINS.includes(origin)) ? origin : (ALLOWED_ORIGINS[0] || '');
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Vary': 'Origin',
  };
}

function jsonResponse(data: unknown, status = 200, requestOrigin: string | null = null) {
  return NextResponse.json(data, {
    status,
    headers: getCorsHeaders(requestOrigin ?? null),
  });
}

export async function OPTIONS(request: Request) {
  const origin = request.headers.get('origin');
  return new NextResponse(null, { status: 204, headers: getCorsHeaders(origin) });
}

const inquiryRateLimit = new Map<string, { count: number; resetAt: number }>();
const INQUIRY_RATE_WINDOW = 60_000;
const INQUIRY_RATE_MAX = 10;

function checkInquiryRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = inquiryRateLimit.get(ip);
  if (!entry || now > entry.resetAt) {
    inquiryRateLimit.set(ip, { count: 1, resetAt: now + INQUIRY_RATE_WINDOW });
    return true;
  }
  if (entry.count >= INQUIRY_RATE_MAX) return false;
  entry.count++;
  return true;
}

export async function POST(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const body = await request.json();
    const { nationalId, phone } = body;

    const ip = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || 'unknown';
    if (!checkInquiryRateLimit(ip)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' }, 429, origin);
    }

    if (!nationalId || nationalId.length !== 14) {
      return jsonResponse({ error: 'الرقم القومي يجب أن يتكون من 14 رقماً' }, 400, origin);
    }
    if (!phone || !/^(010|011|012|015)\d{8}$/.test(phone)) {
      return jsonResponse({ error: 'رقم الهاتف المصري غير صحيح' }, 400, origin);
    }

    const supabase = getAdminClient();

    const [studentRes, levelsRes] = await Promise.all([
      supabase
        .from('students')
        .select('id, student_code, name, phone, national_id, age, gender, level, selected_rewaya, branch_name, memorization_amount, memorizer_name, memorizer_phone, memorizer_address, location, birth_date, score, rewaya_score, tajweed_score, voice_score, meaning_score, profile_image_url, birth_certificate_url, exam_date, exam_hour, notes, created_at')
        .eq('national_id', nationalId)
        .eq('phone', phone)
        .maybeSingle(),
      supabase
        .from('competition_levels')
        .select('id, title, content, is_active')
        .eq('is_active', true)
    ]);

    const { data: student, error: studentError } = studentRes;
    const { data: levels, error: levelsError } = levelsRes;

    if (studentError) {
      console.error('Database error fetching student:', studentError);
      return jsonResponse({ error: 'حدث خطأ في قاعدة البيانات أثناء البحث' }, 500, origin);
    }

    if (!student) {
      return jsonResponse({ error: 'لم يُعثر على متسابق بهذه البيانات. تأكد من الرقم القومي ورقم الهاتف المسجّل.' }, 404, origin);
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
