// Server Component — pre-fetches registration status before HTML is sent
// force-dynamic: يمنع Next.js من تخزين الصفحة - يتم فحص حالة التسجيل مع كل طلب
export const dynamic = 'force-dynamic';

import { createClient } from '@supabase/supabase-js';
import RegisterClient from './RegisterClient';

async function getRegistrationStatus() {
  try {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !key) return { allowed: false, capacityFull: false };

    const supabase = createClient(url, key, { auth: { persistSession: false } });

    let isOpen: boolean | null = null;
    let hasSlots: boolean | null = null;

    try {
      const rpcRes = await supabase.rpc('public_get_registration_status').single();
      const status = rpcRes.data as Record<string, unknown> | null;
      if (status) {
        isOpen = status.is_registration_open === true;
        hasSlots = status.has_available_slots === true;
      }
    } catch (e) { console.error('Failed to fetch registration status via RPC:', e); }

    if (isOpen === null || hasSlots === null) {
      const [settingsRes, countRes] = await Promise.all([
        supabase.from('app_settings').select('is_registration_open, exam_schedule').eq('id', 1).single(),
        supabase.from('students').select('id', { count: 'exact', head: true }),
      ]);
      const settings = settingsRes.data as Record<string, unknown> | null;
      if (settings) {
        if (isOpen === null) isOpen = settings.is_registration_open === true;
        if (hasSlots === null) {
          const schedule = settings.exam_schedule as Array<Record<string, unknown>> | null;
          let totalCap = 0;
          if (schedule && Array.isArray(schedule)) {
            for (const slot of schedule) {
              totalCap += ((slot.end_hour as number || 13) - (slot.start_hour as number || 8)) * (slot.students_per_hour as number || 4);
            }
          }
          const count = countRes.count ?? 0;
          hasSlots = totalCap > count;
        }
      }
    }

    // لو مش قادرين نحدد الحالة بوضوح، نقفل التسجيل (fail-closed)
    if (isOpen === null) isOpen = false;
    if (hasSlots === null) hasSlots = false;

    if (isOpen === false) return { allowed: false, capacityFull: false };
    if (hasSlots === false) return { allowed: false, capacityFull: true };
  } catch (e) {
    console.error('Failed to determine registration status:', e);
    return { allowed: false, capacityFull: false };
  }

  return { allowed: true, capacityFull: false };
}

export default async function RegisterPage() {
  const { allowed, capacityFull } = await getRegistrationStatus();
  return <RegisterClient initialAllowed={allowed} initialCapacityFull={capacityFull} />;
}
