import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function GET() {
  try {
    const { data, error } = await supabase
      .from('app_settings')
      .select('faqs')
      .eq('id', 1)
      .single();

    if (error) return NextResponse.json({ data: [] });

    const faqs = (data?.faqs as { q: string; a: string }[]) ?? [];

    return NextResponse.json(
      { data: faqs },
      { headers: { 'Cache-Control': 'public, max-age=300, stale-while-revalidate=600' } }
    );
  } catch {
    return NextResponse.json({ data: [] });
  }
}
