import { getSupabase } from '@/lib/supabase';
import { jsonResponse, optionsResponse, checkRateLimit, getClientIp } from '@/lib/api-utils';

const DEFAULT_FAQS = [
  { q: 'كيف أعرف أن تسجيلي تم بنجاح؟', a: 'بعد إتمام التسجيل ستظهر لك استمارة إلكترونية برقم تسجيل خاص، كما يمكنك الاستعلام في أي وقت من بوابة الاستعلامات.' },
  { q: 'هل يمكنني تغيير المستوى بعد التسجيل؟', a: 'لا يمكن تغيير المستوى بعد تأكيد التسجيل. ننصح باختيار المستوى المناسب بعناية قبل الإرسال.' },
  { q: 'كيف أعرف موعد اختباري؟', a: 'بعد اكتمال التسجيل، يتم تحديد الموعد تلقائياً ويظهر في بوابة الاستعلام عن الاستمارة برقمك القومي ورقم هاتفك.' },
  { q: 'ما هي معايير التقييم في المسابقة؟', a: 'يتم التقييم على: الحفظ وجودة التلاوة، أحكام التجويد، حسن الصوت والأداء، ومعاني الكلمات حسب المستوى.' },
];

export { optionsResponse as OPTIONS };

export async function GET(request: Request) {
  const origin = request.headers.get('origin');
  const ip = getClientIp(request);
  if (!checkRateLimit(ip, 30)) {
    return jsonResponse({ data: DEFAULT_FAQS }, 200, origin, 60);
  }

  try {
    const supabase = getSupabase();

    const timeout = new Promise<{ data: { faqs: { q: string; a: string }[] } | null; error: null }>((resolve) => {
      setTimeout(() => resolve({ data: null, error: null }), 2500);
    });

    const query = supabase
      .from('app_settings')
      .select('faqs')
      .limit(1)
      .maybeSingle();

    const result = await Promise.race([query, timeout]);
    const { data, error } = result as { data: { faqs: { q: string; a: string }[] } | null; error: Error | null };

    if (error) {
      return jsonResponse({ data: DEFAULT_FAQS }, 200, origin, 60);
    }

    const faqs = (data?.faqs as { q: string; a: string }[]) ?? [];
    const resultFaqs = faqs.length > 0 ? faqs : DEFAULT_FAQS;

    return jsonResponse({ data: resultFaqs }, 200, origin, 60);
  } catch {
    return jsonResponse({ data: DEFAULT_FAQS }, 200, origin, 60);
  }
}
