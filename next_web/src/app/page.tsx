'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import CountUp from '@/components/CountUp';
import { motion } from 'framer-motion';
import { supabase } from '@/lib/supabase';

const features = [
  { icon: 'app_registration', title: 'التسجيل الذكي', desc: 'نظام تسجيل متكامل من ٥ خطوات مع رفع المستندات وتحديد المستوى حسب الحفظ والعمر والتحقق الفوري من السعة المتاحة.' },
  { icon: 'calendar_month', title: 'جدولة الاختبارات', desc: 'مواعيد اختبار محددة بأيام وساعات دقيقة مع توزيع المتسابقين على الفترات المتاحة حسب السعة الاستيعابية لكل توقيت.' },
  { icon: 'gavel', title: 'التحكيم الرقمي', desc: 'نظام توثيق رقمي لدرجات المتسابقين مع احتساب آلي للنسب المئوية وتحديد دقيق لنتائج التقييم في كل مستوى.' },
  { icon: 'analytics', title: 'النتائج الفورية', desc: 'إعلان النتائج فور اعتمادها مع إمكانية طباعة الشهادات والاستعلام عن أهلية حضور حفل التكريم.' },
];

interface LiveStats {
  levelCount: number;
  totalCapacity: number;
  daysLeft: number;
  registeredCount: number;
}

const journey = [
  { icon: 'how_to_reg', title: 'التسجيل', desc: 'قم بتسجيل بياناتك ورفع المستندات المطلوبة لإنشاء ملفك في المسابقة.' },
  { icon: 'edit_note', title: 'الاختبار', desc: 'خضع للتقييم في الموعد المحدد من قبل لجنة التحكيم المتخصصة.' },
  { icon: 'event_available', title: 'الاستعلام عن الحفل', desc: 'استعلم عن أهليتك لحضور حفل التكريم من خلال المنصة.' },
  { icon: 'emoji_events', title: 'حضور الحفل', desc: 'احضر الحفل الختامي واستلم شهادتك وجائزتك.' },
  { icon: 'analytics', title: 'الاستعلام عن النتيجة', desc: 'اطلع على نتيجتك النهائية بعد اعتمادها من اللجنة العليا.' },
];

export default function HomePage() {
  const fullTitle = 'مسابقة أهل القرآن الكبرى';
  const [displayedTitle, setDisplayedTitle] = useState('');
  const [showCursor, setShowCursor] = useState(true);
  const [titleDone, setTitleDone] = useState(false);

  useEffect(() => {
    let i = 0;
    const interval = setInterval(() => {
      i++;
      setDisplayedTitle(fullTitle.slice(0, i));
      if (i >= fullTitle.length) {
        clearInterval(interval);
        setTitleDone(true);
        setTimeout(() => setShowCursor(false), 2000);
      }
    }, 90);
    return () => clearInterval(interval);
  }, []);

  const paragraphText = 'رحلة إيمانية نحو التميز في كتاب الله، حيث تلتقي التقنية الحديثة بقدسية التلاوة لتكريم حفظة كتاب الله.';

  const [openFaq, setOpenFaq] = useState(-1);
  const [faq, setFaq] = useState<{ q: string; a: string }[]>([]);

  useEffect(() => {
    fetch('/api/faq')
      .then((res) => res.json())
      .then((json) => { if (json.data) setFaq(json.data); })
      .catch(() => {});
  }, []);

  const [liveStats, setLiveStats] = useState<LiveStats>({ levelCount: 0, totalCapacity: 0, daysLeft: 0, registeredCount: 0 });
  const [statsInView, setStatsInView] = useState(false);
  const statsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) setStatsInView(true); },
      { threshold: 0.4 }
    );
    if (statsRef.current) obs.observe(statsRef.current);
    return () => obs.disconnect();
  }, []);

  useEffect(() => {
    async function fetchStats() {
      try {
        const { data: levels } = await supabase
          .from('competition_levels')
          .select('max_capacity')
          .eq('is_active', true);

        const { data: settings } = await supabase
          .from('app_settings')
          .select('registration_end_date')
          .eq('id', 1)
          .maybeSingle();

        const { count: studentCount } = await supabase
          .from('students')
          .select('*', { count: 'exact', head: true });

        const levelCount = levels?.length ?? 0;
        const totalCapacity = levels?.reduce((sum, l) => sum + (l.max_capacity ?? 0), 0) ?? 0;
        const registeredCount = studentCount ?? 0;

        let daysLeft = 0;
        if (settings?.registration_end_date) {
          const end = new Date(settings.registration_end_date);
          const now = new Date();
          daysLeft = Math.max(0, Math.ceil((end.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));
        }

        setLiveStats({ levelCount, totalCapacity, daysLeft, registeredCount });
      } catch { }
    }
    fetchStats();
  }, []);

  return (
    <div className="min-h-screen bg-surface font-cairo" dir="rtl">
      <Header />

      {/* ─── HERO ─── */}
      <section className="relative min-h-[75vh] md:min-h-[85vh] flex items-center overflow-hidden bg-primary-container">
        {/* Islamic pattern — very subtle */}
        <div className="absolute inset-0 islamic-pattern z-0 opacity-[0.5]" />

        {/* Soft gold glow from behind */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1.5, ease: 'easeOut' }}
          className="absolute -top-32 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-secondary-fixed/8 rounded-full blur-[120px] pointer-events-none z-[1]"
        />

        {/* Decorative blobs */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1.5, ease: 'easeOut', delay: 0.2 }}
          className="absolute -bottom-48 -right-48 w-[600px] h-[600px] bg-secondary-fixed/6 rounded-full blur-[150px] pointer-events-none z-[1]"
        />
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1.5, ease: 'easeOut', delay: 0.4 }}
          className="absolute -top-48 -left-48 w-[500px] h-[500px] bg-white/4 rounded-full blur-[150px] pointer-events-none z-[1]"
        />

        {/* Subtle dark overlay for depth */}
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-primary-container/60 z-[2]" />

        {/* Smooth transition to next section */}
        <div className="absolute inset-x-0 bottom-0 h-32 bg-gradient-to-t from-surface to-transparent z-[3] pointer-events-none" />

        <div className="max-w-7xl mx-auto px-6 relative z-10 text-center w-full py-24">
          <motion.h1
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
            className="text-[32px] sm:text-[44px] md:text-[56px] font-black text-white leading-[1.15] mb-5 min-h-[1.2em]"
            style={{ fontFamily: "'Noto Serif', serif", textShadow: titleDone ? '0 0 30px rgba(255,224,136,0.25)' : 'none' }}
          >
            <span className={titleDone ? '' : 'animate-title-glow'}>
              {displayedTitle}
            </span>
            {showCursor && displayedTitle.length < fullTitle.length && (
              <span className="inline-block w-[3px] h-[0.9em] bg-secondary-fixed mr-1 animate-pulse align-middle" />
            )}
          </motion.h1>

          <motion.p
            initial="hidden"
            animate="visible"
            variants={{
              visible: { transition: { staggerChildren: 0.035, delayChildren: 2.5 } }
            }}
            className="text-base sm:text-lg text-on-primary-container max-w-2xl mx-auto mb-10 leading-relaxed opacity-90 overflow-hidden"
          >
            {paragraphText.split(' ').map((word, i) => (
              <motion.span
                key={i}
                variants={{
                  hidden: { opacity: 0, y: 12, filter: 'blur(4px)' },
                  visible: { opacity: 1, y: 0, filter: 'blur(0px)' }
                }}
                transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                className="inline-block ml-1"
              >
                {word}
              </motion.span>
            ))}
          </motion.p>

          <motion.div
            initial="hidden"
            animate="visible"
            variants={{
              hidden: {},
              visible: { transition: { staggerChildren: 0.15, delayChildren: 3.8 } }
            }}
            className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center items-stretch sm:items-center w-full max-w-md sm:max-w-none mx-auto"
          >
            <motion.div
              variants={{
                hidden: { opacity: 0, y: 20, scale: 0.9 },
                visible: { opacity: 1, y: 0, scale: 1 }
              }}
              transition={{ type: 'spring', stiffness: 200, damping: 14 }}
              className="w-full sm:w-auto"
            >
              <Link href="/register" className="inline-flex w-full sm:w-auto bg-secondary-fixed text-on-secondary-fixed px-5 sm:px-6 py-3 sm:py-2.5 rounded-xl font-bold text-sm shadow-xl hover:bg-secondary-container active:scale-95 transition-all duration-300 items-center justify-center gap-2 whitespace-nowrap">
                <span className="material-symbols-outlined text-base sm:text-lg">person_add</span>
                سجل الآن
              </Link>
            </motion.div>
            <motion.div
              variants={{
                hidden: { opacity: 0, y: 20, scale: 0.9 },
                visible: { opacity: 1, y: 0, scale: 1 }
              }}
              transition={{ type: 'spring', stiffness: 200, damping: 14 }}
              className="w-full sm:w-auto"
            >
              <Link href="/status?tab=result" className="inline-flex w-full sm:w-auto bg-transparent border-2 border-primary-fixed text-primary-fixed px-5 sm:px-6 py-3 sm:py-2.5 rounded-xl font-bold text-sm hover:bg-primary-fixed/10 active:scale-95 transition-all duration-300 items-center justify-center gap-2 whitespace-nowrap">
                <span className="material-symbols-outlined text-lg">search</span>
                الاستعلام عن النتيجة
              </Link>
            </motion.div>
          </motion.div>
        </div>

        {/* Scroll Indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 4, duration: 0.5 }}
          className="absolute bottom-6 left-1/2 -translate-x-1/2 animate-bounce z-10"
        >
          <span className="material-symbols-outlined text-secondary-fixed text-3xl">expand_more</span>
        </motion.div>
      </section>

      {/* ─── STATS ─── */}
      <section ref={statsRef} className="py-16 bg-surface">
        <div className="max-w-7xl mx-auto px-6 grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="group"
          >
            <div className="text-4xl md:text-5xl font-black text-primary mb-2 group-hover:scale-110 transition-transform">
              {statsInView ? <CountUp end={liveStats.levelCount} duration={2} /> : '٠'}
            </div>
            <div className="text-secondary font-bold text-sm">مستوى فني</div>
          </motion.div>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.15 }}
            className="group"
          >
            <div className="text-4xl md:text-5xl font-black text-primary mb-2 group-hover:scale-110 transition-transform">
              {statsInView ? <CountUp end={liveStats.totalCapacity} duration={2.5} /> : '٠'}
            </div>
            <div className="text-secondary font-bold text-sm">العدد المطلوب</div>
          </motion.div>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="group"
          >
            <div className="text-4xl md:text-5xl font-black text-primary mb-2 group-hover:scale-110 transition-transform">
              {statsInView ? <CountUp end={liveStats.daysLeft} duration={1.5} /> : '٠'}
            </div>
            <div className="text-secondary font-bold text-sm">أيام للتسجيل</div>
          </motion.div>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.45 }}
            className="group"
          >
            <div className="text-4xl md:text-5xl font-black text-primary mb-2 group-hover:scale-110 transition-transform">
              {statsInView ? <CountUp end={liveStats.registeredCount} duration={3} /> : '٠'}
            </div>
            <div className="text-secondary font-bold text-sm">إجمالي المتسابقين</div>
          </motion.div>
        </div>
      </section>

      {/* ─── FEATURES ─── */}
      <section className="py-16 bg-surface-container-low">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="text-center mb-14"
          >
            <span className="text-secondary font-bold text-sm mb-2 block">مميزاتنا</span>
            <h2 className="text-[30px] md:text-[38px] font-black text-primary"
              style={{ fontFamily: "'Noto Serif', serif" }}>
              منظومة رقمية متكاملة
            </h2>
          </motion.div>

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-50px' }}
            variants={{
              hidden: {},
              visible: { transition: { staggerChildren: 0.1 } }
            }}
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5"
          >
            {features.map((f, i) => (
              <motion.div
                key={i}
                variants={{
                  hidden: { opacity: 0, y: 20 },
                  visible: { opacity: 1, y: 0 }
                }}
                transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                className="group"
              >
                <div className="glass-card p-7 rounded-2xl h-full transition-all duration-500 hover:-translate-y-1 hover:shadow-lg relative overflow-hidden">
                  <div className="absolute -top-8 -right-8 w-24 h-24 rounded-full opacity-[0.04] pointer-events-none"
                    style={{ background: `radial-gradient(circle, #735c00 0%, transparent 70%)` }}
                  />
                  <div className="w-12 h-12 rounded-xl bg-primary-container/10 flex items-center justify-center mb-4 text-primary group-hover:bg-primary group-hover:text-white transition-all duration-400">
                    <span className="material-symbols-outlined text-xl">{f.icon}</span>
                  </div>
                  <h3 className="text-base font-black text-primary mb-2">{f.title}</h3>
                  <p className="text-on-surface-variant text-sm leading-relaxed">{f.desc}</p>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* ─── JOURNEY ─── */}
      <section className="py-16 bg-surface overflow-hidden">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="text-center mb-12"
          >
            <span className="text-secondary font-bold text-sm mb-2 block">خطوات المتسابق</span>
            <h2 className="text-[30px] md:text-[38px] font-black text-primary"
              style={{ fontFamily: "'Noto Serif', serif" }}>
              رحلة المتسابق
            </h2>
          </motion.div>

          {/* ── Desktop: horizontal connected circles ── */}
          <div className="hidden lg:block">
            <div className="relative pt-2">
              <div className="absolute top-[30px] right-0 left-0 h-[2px] bg-gradient-to-l from-secondary/15 via-secondary/10 to-secondary/15 rounded-full" />
              <div className="grid grid-cols-5 gap-4 relative">
                {journey.map((step, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.5, delay: i * 0.1 }}
                    className="flex flex-col items-center text-center group"
                  >
                    <div className="relative mb-5">
                      <div className="w-[60px] h-[60px] rounded-full bg-white border-2 border-secondary/20 flex items-center justify-center shadow-sm group-hover:shadow-lg group-hover:border-secondary transition-all duration-500 relative z-10">
                        <span className="absolute -top-1.5 -left-1.5 w-6 h-6 rounded-full bg-secondary text-white flex items-center justify-center text-[11px] font-black shadow-sm">
                          {i + 1}
                        </span>
                        <span className="material-symbols-outlined text-secondary text-2xl">{step.icon}</span>
                      </div>
                    </div>
                    <h4 className="font-black text-primary text-sm mb-1.5">{step.title}</h4>
                    <p className="text-on-surface-variant text-[11px] leading-relaxed px-1">{step.desc}</p>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>

          {/* ── Mobile/Tablet: vertical timeline ── */}
          <div className="lg:hidden">
            <div className="relative">
              <div className="absolute right-[23px] top-2 bottom-2 w-[2px] bg-secondary/10 rounded-full" />
              <div className="space-y-0">
                {journey.map((step, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, x: -15 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.5, delay: i * 0.08 }}
                    className="relative flex gap-4 pb-7 last:pb-0"
                  >
                    {/* Circle + line connector */}
                    <div className="relative z-10 flex-shrink-0 w-[48px] h-[48px] rounded-full bg-white border-2 border-secondary/15 flex items-center justify-center shadow-sm group-hover:border-secondary transition-colors duration-300">
                      <span className="text-secondary font-black text-sm">{i + 1}</span>
                    </div>
                    {/* Content card */}
                    <div className="flex-1 min-w-0 bg-white/60 rounded-2xl p-4 border border-secondary/5 shadow-sm">
                      <div className="flex items-center gap-2 mb-1.5">
                        <span className="material-symbols-outlined text-secondary text-lg">{step.icon}</span>
                        <h4 className="font-black text-primary text-sm">{step.title}</h4>
                      </div>
                      <p className="text-on-surface-variant text-xs leading-relaxed">{step.desc}</p>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─── FAQ ─── */}
      {faq.length > 0 && (
      <section className="py-16 bg-surface-container-low">
        <div className="max-w-3xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="text-center mb-12"
          >
            <span className="text-secondary font-bold text-sm mb-2 block">الأسئلة الشائعة</span>
            <h2 className="text-[30px] md:text-[38px] font-black text-primary"
              style={{ fontFamily: "'Noto Serif', serif" }}>
              إجابات لاستفساراتك
            </h2>
          </motion.div>

          <div className="space-y-3">
            {faq.map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 15 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: i * 0.06 }}
                className={`rounded-2xl border transition-all duration-300 overflow-hidden ${
                  openFaq === i
                    ? 'bg-white border-secondary/15 shadow-sm'
                    : 'bg-white/50 border-secondary/5 hover:border-secondary/10'
                }`}
              >
                <button
                  onClick={() => setOpenFaq(openFaq === i ? -1 : i)}
                  className="w-full flex items-center justify-between gap-3 p-5 text-right"
                >
                  <span className="font-black text-primary text-sm flex-1">{item.q}</span>
                  <motion.span
                    animate={{ rotate: openFaq === i ? 180 : 0 }}
                    transition={{ duration: 0.2 }}
                    className="material-symbols-outlined text-secondary/40 text-xl flex-shrink-0"
                  >
                    expand_more
                  </motion.span>
                </button>
                <motion.div
                  initial={false}
                  animate={{
                    height: openFaq === i ? 'auto' : 0,
                    opacity: openFaq === i ? 1 : 0,
                  }}
                  transition={{ duration: 0.25, ease: 'easeInOut' }}
                  className="overflow-hidden"
                >
                  <div className="px-5 pb-5 pt-0 text-on-surface-variant text-sm leading-relaxed border-t border-secondary/5">
                    {item.a}
                  </div>
                </motion.div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>
      )}



      <Footer />
    </div>
  );
}
