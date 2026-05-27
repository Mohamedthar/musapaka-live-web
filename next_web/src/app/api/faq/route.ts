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
    const { data, error } = await supabase
      .from('app_settings')
      .select('faqs')
      .limit(1)
      .maybeSingle();

    if (error) {
      console.error('FAQ fetch error:', error);
      return NextResponse.json({ data: DEFAULT_FAQS });
    }

    const faqs = (data?.faqs as { q: string; a: string }[]) ?? [];
    const result = faqs.length > 0 ? faqs : DEFAULT_FAQS;

    return NextResponse.json(
      { data: result },
      { headers: { 'Cache-Control': 'no-store' } }
    );
  } catch {
    return NextResponse.json({ data: DEFAULT_FAQS });
  }
}
