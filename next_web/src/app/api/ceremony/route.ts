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
    const { data: settings, error } = await supabase.rpc('public_get_registration_status');

    if (error) {
      return jsonResponse({ error: 'حدث خطأ في قراءة الإعدادات' }, 500, origin);
    }

    const st = settings as Record<string, unknown> | null;
    return jsonResponse({
      is_ceremony_query_open: !!(st as Record<string, unknown> | null)?.is_ceremony_query_open,
      ceremony_query_open_date: (st as Record<string, unknown> | null)?.ceremony_query_open_date ?? null,
    }, 200, origin, 60);
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
    const { data, error } = await supabase.rpc('public_lookup_ceremony', {
      p_national_id: String(nationalId),
    });

    if (error) {
      return jsonResponse({ error: 'حدث خطأ في قاعدة البيانات أثناء البحث' }, 500, origin);
    }

    const result = data as Record<string, unknown> | null;
    if (!result) {
      return jsonResponse({ error: 'لم يُعثر على متسابق بهذا الرقم القومي.' }, 404, origin);
    }

    if (result.error) {
      return jsonResponse(result, !!(result as Record<string, unknown>).closed ? 403 : 400, origin);
    }

    return jsonResponse({ success: true, student: result }, 200, origin);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
