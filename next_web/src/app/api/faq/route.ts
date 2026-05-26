import { NextResponse } from 'next/server';
import { getAdminClient } from '@/lib/supabase-admin';

export async function GET() {
  try {
    const supabase = getAdminClient();
    const { data, error } = await supabase
      .from('app_settings')
      .select('faqs')
      .eq('id', 1)
      .maybeSingle();

    if (error) {
      console.error('FAQ fetch error:', error);
      return NextResponse.json({ data: [] });
    }

    const faqs = (data?.faqs as { q: string; a: string }[]) ?? [];

    return NextResponse.json(
      { data: faqs },
      { headers: { 'Cache-Control': 'no-store' } }
    );
  } catch {
    return NextResponse.json({ data: [] });
  }
}
