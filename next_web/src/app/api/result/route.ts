import { getPublicClient } from '@/lib/supabase-public';
import { getCorsHeaders, jsonResponse, optionsResponse, checkRateLimit, getClientIp } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const supabase = getPublicClient();
    const { data: settings, error } = await supabase.rpc('public_get_registration_status');

    if (error) {
      console.error('Settings error:', error);
      return jsonResponse({ error: 'حدث خطأ في قراءة الإعدادات' }, 500, origin);
    }

    const status = settings as Record<string, unknown> | null;
    return jsonResponse(
      {
        success: true,
        is_result_query_open: !!(status as any)?.is_result_query_open,
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
      return jsonResponse({ error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' }, 429, origin);
    }

    const body = await request.json();
    const { nationalId } = body;

    if (!nationalId || String(nationalId).length !== 14) {
      return jsonResponse({ error: 'الرقم القومي يجب أن يتكون من 14 رقماً' }, 400, origin);
    }

    const supabase = getPublicClient();
    const { data, error } = await supabase.rpc('public_lookup_result', {
      p_national_id: String(nationalId),
    });

    if (error) {
      console.error('Result lookup error:', error);
      return jsonResponse({ error: 'حدث خطأ في قاعدة البيانات أثناء البحث' }, 500, origin);
    }

    const result = data as Record<string, unknown> | null;
    if (!result) {
      return jsonResponse({ error: 'لم يُعثر على متسابق بهذا الرقم القومي.' }, 404, origin);
    }

    if (result.error) {
      return jsonResponse(result, (result as any).closed ? 403 : 400, origin);
    }

    return jsonResponse({ success: true, ...result }, 200, origin);
  } catch (error: unknown) {
    console.error('Result API Error:', error);
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
