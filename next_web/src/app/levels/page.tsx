import { getSupabase } from '@/lib/supabase';
import LevelsClient from './client-page';

export const revalidate = 3600;

export default async function LevelsPage() {
  let levels = null;
  let error = null;

  try {
    const supabase = getSupabase();
    const { data, error: supabaseError } = await supabase
      .from('competition_levels')
      .select('*')
      .eq('is_active', true)
      .order('level_code');

    if (supabaseError) error = supabaseError.message;
    else levels = data;
  } catch (err) {
    error = err instanceof Error ? err.message : 'فشل في تحميل المستويات';
  }

  return <LevelsClient initialLevels={levels} initialError={error} />;
}
