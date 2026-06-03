import { getAdminClient } from '@/lib/supabase-admin';
import { jsonResponse, optionsResponse } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  try {
    const supabase = getAdminClient();

    const [settingsRes, countRes, levelCountsRes] = await Promise.all([
      supabase.from('app_settings').select('*').eq('id', 1).single(),
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
      total_students: countRes.count ?? 0,
      level_counts: levelCounts,
    }, 200, origin, 30);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
