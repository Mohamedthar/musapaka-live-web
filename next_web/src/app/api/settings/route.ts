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

    const [settingsRes, countRes, levelCountsRes] = await Promise.all([
      supabase.from('app_settings').select('*').eq('id', 1).single(),
      supabase.from('students').select('id', { count: 'exact', head: true }),
      // TODO: Replace with RPC get_level_counts() when student count exceeds ~5000
      // Currently fetches all rows to build per-level counts
      supabase.from('students').select('level'),
    ]);

    let statusData: Record<string, unknown> | null = null;
    try {
      const rpcRes = await supabase.rpc('public_get_registration_status').single();
      statusData = rpcRes.data as Record<string, unknown> | null;
    } catch {
      statusData = null;
    }

    const levelCounts: Record<string, number> = {};
    if (levelCountsRes.data) {
      for (const s of levelCountsRes.data) {
        levelCounts[s.level] = (levelCounts[s.level] || 0) + 1;
      }
    }

    return jsonResponse({
      success: true,
      settings: settingsRes.data,
      status: statusData,
      total_students: countRes.count ?? 0,
      level_counts: levelCounts,
    }, 200, origin, 5);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
