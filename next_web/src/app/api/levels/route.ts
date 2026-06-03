import { getAdminClient } from '@/lib/supabase-admin';
import { jsonResponse, optionsResponse } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const supabase = getAdminClient();
    const { data, error } = await supabase
      .from('competition_levels')
      .select('*')
      .eq('is_active', true)
      .order('level_code');

    if (error) {
      return jsonResponse({ error: 'حدث خطأ في جلب المستويات' }, 500, origin);
    }

    return jsonResponse({ success: true, levels: data || [] }, 200, origin, 120);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
