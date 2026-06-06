import { getAdminClient } from '@/lib/supabase-admin';
import { jsonResponse, optionsResponse, checkRateLimit, getClientIp, validateCsrf } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 30)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً' }, 429, origin);
    }

    const supabase = getAdminClient();
    const { data: settings, error } = await supabase
      .from('app_settings')
      .select('is_result_query_open, result_query_open_date')
      .eq('id', 1)
      .single();

    if (error || !settings) {
      return jsonResponse({ is_result_query_open: false, result_query_open_date: null }, 200, origin, 60);
    }

    return jsonResponse(
      {
        success: true,
        is_result_query_open: !!(settings as Record<string, unknown>).is_result_query_open,
        result_query_open_date: (settings as Record<string, unknown>).result_query_open_date ?? null,
      },
      200,
      origin,
      60
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}

export async function POST(request: Request) {
  const origin = request.headers.get('origin');

  try {
    if (!validateCsrf(request)) {
      return jsonResponse({ error: 'طلب غير مصرح به' }, 403, origin);
    }
    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 10)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' }, 429, origin);
    }

    const body = await request.json();
    const { nationalId } = body;

    if (!nationalId || String(nationalId).length !== 14) {
      return jsonResponse({ error: 'الرقم القومي يجب أن يتكون من 14 رقماً' }, 400, origin);
    }

    const supabase = getAdminClient();

    const [studentRes, levelsRes] = await Promise.all([
      supabase.rpc('public_lookup_result', { p_national_id: String(nationalId) }),
      supabase
        .from('competition_levels')
        .select('id, title, content, is_active, total_points, has_rewaya, rewaya_max_score, has_tajweed, tajweed_max_score, has_voice, voice_max_score, has_meaning, meaning_max_score')
        .eq('is_active', true),
    ]);

    const { data, error } = studentRes;
    const { data: levels } = levelsRes;

    if (error) {
      console.error('[result] RPC error:', error);
      return jsonResponse({ error: 'حدث خطأ في قاعدة البيانات أثناء البحث' }, 500, origin);
    }

    const student = Array.isArray(data) ? data[0] : data;
    if (!student) {
      return jsonResponse({ error: 'لم يُعثر على متسابق بهذا الرقم القومي.' }, 404, origin);
    }

    if (student.error) {
      return jsonResponse(student, !!(student as Record<string, unknown>).closed ? 403 : 400, origin);
    }

    const level = (levels as Array<Record<string, unknown>> | null)?.find(
      l => l.title === (student as Record<string, unknown>).level
    ) ?? null;

    return jsonResponse({
      success: true,
      student,
      level,
    }, 200, origin);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
