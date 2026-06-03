import { getAdminClient } from '@/lib/supabase-admin';
import { jsonResponse, optionsResponse, checkRateLimit, getClientIp } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function POST(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 20)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' }, 429, origin);
    }

    const body = await request.json();
    const { name, national_id } = body;

    if (!name && !national_id) {
      return jsonResponse({ error: 'يجب توفير الاسم أو الرقم القومي' }, 400, origin);
    }

    const supabase = getAdminClient();
    const checks: Record<string, boolean> = {};

    if (name && typeof name === 'string' && name.trim().length >= 3) {
      const { data: nameData } = await supabase
        .from('students')
        .select('id')
        .eq('name', name.trim())
        .maybeSingle();
      checks.name_exists = !!nameData;
    }

    if (national_id && typeof national_id === 'string' && national_id.trim().length === 14) {
      const { data: idData } = await supabase
        .from('students')
        .select('id')
        .eq('national_id', national_id.trim())
        .maybeSingle();
      checks.national_id_exists = !!idData;
    }

    return jsonResponse({ success: true, ...checks }, 200, origin);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
