import { getAdminClient } from '@/lib/supabase-admin';
import { jsonResponse, optionsResponse, checkRateLimit, getClientIp } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 30)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً' }, 429, origin);
    }

    const supabase = getAdminClient();

    const [settingsRes, statusRes, countRes, levelCountsRes] = await Promise.all([
      supabase.from('app_settings').select('*').eq('id', 1).single(),
      supabase.rpc('public_get_registration_status').single(),
      supabase.from('students').select('id', { count: 'exact', head: true }),
      supabase.from('students').select('level'),
    ]);

    const levelCounts: Record<string, number> = {};
    if (levelCountsRes.data) {
      for (const s of levelCountsRes.data) {
        levelCounts[s.level] = (levelCounts[s.level] || 0) + 1;
      }
    }

    return jsonResponse({
      success: true,
      settings: settingsRes.data,
      status: statusRes.data,
      total_students: countRes.count ?? 0,
      level_counts: levelCounts,
    }, 200, origin, 30);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
