import { createClient, SupabaseClient } from '@supabase/supabase-js';

let _admin: SupabaseClient | null = null;

export function getAdminClient(): SupabaseClient {
  if (!_admin) {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url) {
      throw new Error('NEXT_PUBLIC_SUPABASE_URL is not set. This variable is required for admin client initialization.');
    }
    if (!key) {
      throw new Error('SUPABASE_SERVICE_ROLE_KEY is not set. This key is required for admin operations.');
    }
    _admin = createClient(url, key, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false,
      },
    });
  }
  return _admin;
}
