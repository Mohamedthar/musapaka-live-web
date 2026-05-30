import { NextResponse } from 'next/server';
import { getPublicClient } from '@/lib/supabase-public';

const DEFAULT_FAQS = [
  { q: 'كيف أعرف أن تسجيلي تم بنجاح؟', a: 'بعد إتمام التسجيل ستظهر لك استمارة إلكترونية برقم تسجيل خاص، كما يمكنك الاستعلام في أي وقت من بوابة الاستعلامات.' },
  { q: 'هل يمكنني تغيير المستوى بعد التسجيل؟', a: 'لا يمكن تغيير المستوى بعد تأكيد التسجيل. ننصح باختيار المستوى المناسب بعناية قبل الإرسال.' },
  { q: 'كيف أعرف موعد اختباري؟', a: 'بعد اكتمال التسجيل، يتم تحديد الموعد تلقائياً ويظهر في بوابة الاستعلام عن الاستمارة برقمك القومي ورقم هاتفك.' },
  { q: 'ما هي معايير التقييم في المسابقة؟', a: 'يتم التقييم على: الحفظ وجودة التلاوة، أحكام التجويد، حسن الصوت والأداء، ومعاني الكلمات حسب المستوى.' },
];

export async function GET() {
  try {
    const supabase = getPublicClient();

    const timeout = new Promise<{ data: { faqs: { q: string; a: string }[] } | null; error: null }>((resolve) => {
      setTimeout(() => resolve({ data: null, error: null }), 2500);
    });

    const query = supabase
      .from('app_settings')
      .select('faqs')
      .limit(1)
      .maybeSingle();

    const result = await Promise.race([query, timeout]);
    const { data, error } = result as { data: { faqs: { q: string; a: string }[] } | null; error: any };

    if (error) {
      console.error('FAQ fetch error:', error);
      return NextResponse.json({ data: DEFAULT_FAQS }, {
        headers: { 'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300' },
      });
    }

    const faqs = (data?.faqs as { q: string; a: string }[]) ?? [];
    const result_faqs = faqs.length > 0 ? faqs : DEFAULT_FAQS;

    return NextResponse.json({ data: result_faqs }, {
      headers: { 'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300' },
    });
  } catch {
    return NextResponse.json({ data: DEFAULT_FAQS }, {
      headers: { 'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300' },
    });
  }
}
