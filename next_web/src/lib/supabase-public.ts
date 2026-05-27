import { getSupabase } from '@/lib/supabase';

let _publicClient: ReturnType<typeof getSupabase> | null = null;

export function getPublicClient() {
  if (!_publicClient) {
    _publicClient = getSupabase();
  }
  return _publicClient;
}
