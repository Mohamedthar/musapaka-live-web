'use client';

import React, { useState, useEffect, useRef, useCallback } from 'react';
import Link from 'next/link';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import { motion } from 'framer-motion';
import { UserPlus, CalendarCheck, ChevronDown, UserCheck, FilePen, Trophy, BarChart3 } from 'lucide-react';

const journey = [
  { Icon: UserCheck, title: 'التسجيل', desc: 'قم بتسجيل بياناتك ورفع المستندات المطلوبة لإنشاء ملفك في المسابقة.' },
  { Icon: FilePen, title: 'الاختبار', desc: 'الحضور في الموعد المحدد لك الموضح في استمارة القبول.' },
  { Icon: CalendarCheck, title: 'الاستعلام عن الحفل', desc: 'بعد الاختبارات سنعلن عن موعد للاستعلام عن حضور الحفل عن طريق الرقم القومي.' },
  { Icon: Trophy, title: 'حضور الحفل', desc: 'يلزمك حضور الحفلة، وإحضار بطاقة الدعوة معك.' },
  { Icon: BarChart3, title: 'الاستعلام عن النتيجة', desc: 'بعد الانتهاء من الحفلة سيتمكن الجميع من معرفة درجته من خلال بوابة الاستعلام عن النتيجة.' },
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
        setTimeout(() => setShowCursor(false), 800);
      }
    }, 20);
    return () => clearInterval(interval);
  }, []);

  const paragraphText = 'هذه المسابقة تأسست عام 2000 وبفضل الله هي الآن في نسختها السادسة والعشرون وهذا النسخة من المسابقة اول نسخة الكترونية';

  const currentYear = new Date().getFullYear();
  const [yearCount, setYearCount] = useState(currentYear);
  const [startYearAnim, setStartYearAnim] = useState(false);
  const yearRaf = useRef(0);

  useEffect(() => {
    const t = setTimeout(() => setStartYearAnim(true), 1800);
    return () => clearTimeout(t);
  }, []);

  const animateYear = useCallback(() => {
    const range = currentYear - 2000;
    const start = performance.now();
    const loop = () => {
      const elapsed = performance.now() - start;
      const progress = Math.min(elapsed / 3000, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      setYearCount(Math.round(currentYear - eased * range));
      if (progress < 1) yearRaf.current = requestAnimationFrame(loop);
    };
    yearRaf.current = requestAnimationFrame(loop);
  }, [currentYear]);

  useEffect(() => {
    if (startYearAnim) animateYear();
    return () => cancelAnimationFrame(yearRaf.current);
  }, [startYearAnim, animateYear]);

  const [openFaq, setOpenFaq] = useState(-1);
  const [faq, setFaq] = useState<{ q: string; a: string }[]>([]);

  useEffect(() => {
    let cancelled = false;
    const loadFaq = async () => {
      for (let i = 0; i < 3; i++) {
        try {
          const res = await fetch('/api/faq');
          const json = await res.json();
          if (!cancelled && json.data) setFaq(json.data);
          return;
        } catch (_) {
          if (i < 2) await new Promise(r => setTimeout(r, 1000 * (i + 1)));
        }
      }
    };
    loadFaq();
    return () => { cancelled = true; };
  }, []);

  return (
    <div className="min-h-screen bg-surface font-cairo flex flex-col" dir="rtl">
      <Header />

      <div className="flex-1">
        {/* ─── HERO ─── */}
      <section className="relative min-h-[60vh] md:min-h-[70vh] flex items-center overflow-hidden bg-primary" style={{ clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 30px), 0 100%)' }}>
        {/* Islamic pattern — very subtle */}
        <div className="absolute inset-0 islamic-pattern z-0 opacity-[0.5]" />

        {/* Background image */}
        <motion.div
          initial={{ opacity: 0, scale: 1.05 }}
          animate={{ opacity: 0.55, scale: 1 }}
          transition={{ duration: 2, ease: 'easeOut' }}
          className="absolute inset-0 z-[1]"
        >
          <div
            className="absolute inset-0 bg-cover bg-center"
            style={{
              backgroundImage: "url('/background.png')",
              backgroundPosition: 'center 40%',
            }}
          />
          <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-transparent to-primary/60" />
        </motion.div>

        {/* Soft gold glow from behind */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1.5, ease: 'easeOut' }}
          className="absolute -top-32 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-secondary-fixed/8 rounded-full blur-[120px] pointer-events-none z-[2]"
        />

        {/* Decorative blobs */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1.5, ease: 'easeOut', delay: 0.2 }}
          className="absolute -bottom-48 -right-48 w-[600px] h-[600px] bg-secondary-fixed/6 rounded-full blur-[150px] pointer-events-none z-[2]"
        />

        {/* Subtle dark overlay for depth */}
        <div className="absolute inset-0 bg-gradient-to-b from-primary/0 via-primary/15 via-50% to-primary/85 to-95% z-[3]" />

        <div className="max-w-7xl mx-auto px-6 relative z-10 text-center w-full py-24">
          <motion.h1
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
            className="text-[36px] sm:text-[48px] md:text-[60px] font-black text-white leading-[1.2] mb-5 min-h-[1.2em]"
            style={{
              fontFamily: "'Noto Serif', serif",
              textShadow: titleDone
                ? '0 0 60px rgba(255,224,136,0.3), 0 0 20px rgba(255,224,136,0.2), 0 4px 12px rgba(0,0,0,0.6)'
                : '0 4px 12px rgba(0,0,0,0.6)',
            }}
          >
            <span className={titleDone ? '' : 'animate-title-glow'}>
              {titleDone ? (
                <>
                  <span>مسابقة أهل </span>
                  <span className="text-secondary-fixed">القرآن</span>
                  <span> الكبرى</span>
                </>
              ) : (
                displayedTitle
              )}
            </span>
            {showCursor && displayedTitle.length < fullTitle.length && (
              <span className="inline-block w-[3px] h-[0.9em] bg-white mr-1 animate-pulse align-middle" />
            )}
          </motion.h1>

          <motion.p
            initial="hidden"
            animate="visible"
            variants={{
              visible: { transition: { staggerChildren: 0.03, delayChildren: 1.2 } }
            }}
            className="text-base sm:text-lg text-white max-w-2xl mx-auto mb-10 leading-relaxed overflow-hidden"
            style={{ textShadow: '0 2px 12px rgba(0,0,0,0.7)' }}
          >
            {paragraphText.split(' ').map((word, i) => {
              if (word === '2000') {
                return (
                  <React.Fragment key={i}>
                    <motion.span
                      variants={{
                        hidden: { opacity: 0, y: 12, filter: 'blur(4px)' },
                        visible: { opacity: 1, y: 0, filter: 'blur(0px)' }
                      }}
                      transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                      className="inline-block"
                    >
                      <motion.strong
                        className="text-secondary-fixed font-black"
                        animate={startYearAnim ? {
                          textShadow: [
                            '0 0 0px rgba(255,224,136,0)',
                            '0 0 16px rgba(255,224,136,0.7)',
                            '0 0 0px rgba(255,224,136,0)',
                          ]
                        } : {}}
                        transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
                      >
                        {startYearAnim ? yearCount : currentYear}
                      </motion.strong>
                    </motion.span>
                    {' '}
                  </React.Fragment>
                );
              }
              return (
                <React.Fragment key={i}>
                  <motion.span
                    variants={{
                      hidden: { opacity: 0, y: 12, filter: 'blur(4px)' },
                      visible: { opacity: 1, y: 0, filter: 'blur(0px)' }
                    }}
                    transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
                    className="inline-block"
                  >
                    {word}
                  </motion.span>
                  {' '}
                </React.Fragment>
              );
            })}
          </motion.p>

          <motion.div
            initial="hidden"
            animate="visible"
            variants={{
              hidden: {},
              visible: { transition: { staggerChildren: 0.15, delayChildren: 2 } }
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
              <Link href="/register" className="inline-flex w-full sm:w-auto bg-gradient-to-l from-[#ffe088] to-[#fed65b] text-[#241a00] px-5 sm:px-6 py-3 sm:py-2.5 rounded-xl font-bold text-sm shadow-2xl shadow-[#ffe088]/30 hover:shadow-[#ffe088]/50 hover:brightness-105 active:scale-95 transition-all duration-300 items-center justify-center gap-2 whitespace-nowrap">
                <UserPlus className="text-base sm:text-lg" />
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
              <Link href="/status?tab=ceremony" className="inline-flex w-full sm:w-auto bg-white/5 border-2 border-white/30 text-white/90 px-5 sm:px-6 py-3 sm:py-2.5 rounded-xl font-bold text-sm backdrop-blur-sm hover:bg-white/15 hover:border-white/50 active:scale-95 transition-all duration-300 items-center justify-center gap-2 whitespace-nowrap">
                <CalendarCheck className="text-lg" />
                الاستعلام عن حضور الحفل
              </Link>
            </motion.div>
          </motion.div>
        </div>

        {/* Scroll Indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 2, duration: 0.5 }}
          className="absolute bottom-6 left-1/2 -translate-x-1/2 animate-bounce z-10"
        >
          <ChevronDown className="text-secondary-fixed text-3xl" />
        </motion.div>
      </section>

      {/* ─── JOURNEY ─── */}
      <section className="section-below-fold relative py-20 bg-gradient-to-b from-surface via-surface to-surface-container-low overflow-hidden">
        <div className="max-w-7xl mx-auto px-6 relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-14"
          >
            <motion.span
              initial={{ opacity: 0, y: -10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-primary text-white font-black text-xs mb-5 shadow-md shadow-primary/20"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-primary-fixed animate-pulse" />
              خطوات المسابقة
            </motion.span>
            <h2 className="text-[30px] md:text-[38px] font-black text-primary"
              style={{ fontFamily: "'Noto Serif', serif" }}>
              رحلة المتسابق
            </h2>
            <div className="flex items-center justify-center gap-2 mt-3">
              <span className="w-8 h-0.5 rounded-full bg-primary/20" />
              <span className="w-2 h-2 rounded-full bg-primary/40" />
              <span className="w-8 h-0.5 rounded-full bg-primary/20" />
            </div>
          </motion.div>

          {/* ── Desktop ── */}
          <div className="hidden lg:block">
            <div className="relative pt-2">
              {/* Connecting line with animation */}
              <div className="absolute top-[32px] right-[8%] left-[8%] h-0.5 rounded-full overflow-hidden">
                <motion.div
                  initial={{ scaleX: 0 }}
                  whileInView={{ scaleX: 1 }}
                  viewport={{ once: true }}
                  transition={{ duration: 1.2, delay: 0.3, ease: 'easeInOut' }}
                  className="absolute inset-0 origin-right bg-gradient-to-l from-secondary-fixed/40 via-secondary/30 to-secondary-fixed/40"
                />
              </div>

              <div className="grid grid-cols-5 gap-4 relative">
                {journey.map((step, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, y: 30 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.5, delay: 0.2 + i * 0.1, ease: 'easeOut' }}
                    whileHover={{ y: -5 }}
                    className="flex flex-col items-center text-center group"
                  >
                    <div className="relative mb-5">
                      {/* Hover glow */}
                      <div className="absolute inset-0 rounded-full bg-secondary/0 group-hover:bg-secondary/10 blur-2xl transition-all duration-500 scale-150" />
                      <motion.div
                        className="relative w-[64px] h-[64px] rounded-full bg-white border-2 border-secondary/20 flex items-center justify-center shadow-sm group-hover:shadow-xl group-hover:border-secondary-fixed transition-all duration-500 z-10"
                        whileHover={{ scale: 1.1 }}
                        transition={{ type: 'spring', stiffness: 300, damping: 15 }}
                      >
                        <motion.span
                          className="absolute -top-1.5 -right-1.5 w-6 h-6 rounded-full bg-secondary text-white flex items-center justify-center text-[11px] font-black shadow-md z-20"
                          whileHover={{ scale: 1.15 }}
                        >
                          {i + 1}
                        </motion.span>
                        <step.Icon className="text-secondary text-2xl" />
                      </motion.div>
                    </div>
                    <h4 className="font-black text-primary text-sm mb-1.5 group-hover:text-secondary transition-colors duration-300">
                      {step.title}
                    </h4>
                    <p className="text-on-surface-variant text-[12px] leading-relaxed px-1">
                      {step.desc}
                    </p>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>

          {/* ── Mobile ── */}
          <div className="lg:hidden">
            <div className="relative">
              <motion.div
                initial={{ scaleY: 0 }}
                whileInView={{ scaleY: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.8, delay: 0.2 }}
                className="absolute right-[23px] top-2 bottom-2 w-[2px] bg-gradient-to-b from-secondary/30 via-secondary/10 to-secondary/30 rounded-full origin-top"
              />
              <div className="space-y-0">
                {journey.map((step, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, x: -20 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.5, delay: i * 0.1, ease: 'easeOut' }}
                    className="relative flex gap-4 pb-8 last:pb-0"
                  >
                    <motion.div
                      className="relative z-10 flex-shrink-0 w-[48px] h-[48px] rounded-full bg-white border-2 border-secondary/20 flex items-center justify-center shadow-md"
                      whileHover={{ scale: 1.1, borderColor: '#735c00' }}
                    >
                      <span className="text-secondary font-black text-sm">{i + 1}</span>
                    </motion.div>
                    <motion.div
                      className="flex-1 min-w-0 bg-white rounded-2xl p-4 border border-secondary/8 shadow-sm hover:shadow-md hover:border-secondary/20 transition-all duration-300"
                      whileHover={{ x: 4 }}
                    >
                      <div className="flex items-center gap-2 mb-1.5">
                        <step.Icon className="text-secondary text-lg" />
                        <h4 className="font-black text-primary text-sm">{step.title}</h4>
                      </div>
                      <p className="text-on-surface-variant text-xs leading-relaxed">{step.desc}</p>
                    </motion.div>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─── FAQ ─── */}
      {faq.length > 0 && (
      <section className="section-below-fold relative py-16 bg-white overflow-hidden">
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-secondary-fixed/[0.04] rounded-full blur-[180px] pointer-events-none" />
        <div className="max-w-3xl mx-auto px-6 relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-14"
          >
            <motion.span
              initial={{ opacity: 0, y: -10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-primary text-white font-black text-xs mb-5 shadow-md shadow-primary/20"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-primary-fixed animate-pulse" />
              الأسئلة الشائعة
            </motion.span>
            <h2 className="text-[30px] md:text-[38px] font-black text-primary"
              style={{ fontFamily: "'Noto Serif', serif" }}>
              إجابات لاستفساراتك
            </h2>
            <div className="flex items-center justify-center gap-2 mt-3">
              <span className="w-8 h-0.5 rounded-full bg-primary/20" />
              <span className="w-2 h-2 rounded-full bg-primary/40" />
              <span className="w-8 h-0.5 rounded-full bg-primary/20" />
            </div>
          </motion.div>

          <div className="space-y-3">
            {faq.map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: i * 0.08, ease: 'easeOut' }}
                className={`rounded-2xl border transition-all duration-300 overflow-hidden ${
                  openFaq === i
                    ? 'bg-surface border-primary/15 shadow-md'
                    : 'bg-surface border-outline-variant/10 hover:border-secondary/12 hover:shadow-sm'
                }`}
              >
                <button
                  onClick={() => setOpenFaq(openFaq === i ? -1 : i)}
                  className="w-full flex items-center gap-4 p-5 text-right group"
                >
                  <span className={`w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black shrink-0 transition-all duration-300 ${
                    openFaq === i
                      ? 'bg-primary text-white shadow-sm'
                      : 'bg-primary/5 text-primary group-hover:bg-primary/10'
                  }`}>
                    {i + 1}
                  </span>
                  <span className={`font-bold text-sm flex-1 text-right transition-colors duration-300 ${
                    openFaq === i ? 'text-primary' : 'text-on-surface'
                  }`}>
                    {item.q}
                  </span>
                  <motion.span
                    animate={{ rotate: openFaq === i ? 180 : 0 }}
                    transition={{ duration: 0.3, ease: 'easeInOut' }}
                    className={`flex-shrink-0 transition-colors duration-300 ${
                      openFaq === i ? 'text-primary' : 'text-on-surface-variant/40'
                    }`}
                  >
                    <ChevronDown />
                  </motion.span>
                </button>
                <motion.div
                  initial={false}
                  animate={{
                    height: openFaq === i ? 'auto' : 0,
                    opacity: openFaq === i ? 1 : 0,
                  }}
                  transition={{ duration: 0.3, ease: 'easeInOut' }}
                  className="overflow-hidden"
                >
                  <div className="px-5 pb-5 text-on-surface-variant/90 text-sm leading-[1.8] bg-white/80 border-t border-outline-variant/10">
                    {item.a}
                  </div>
                </motion.div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>
      )}



      </div>

      <Footer />
    </div>
  );
}
