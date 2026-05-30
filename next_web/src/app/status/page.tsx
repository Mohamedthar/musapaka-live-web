'use client';

import React, { Suspense, useEffect } from 'react';
import dynamic from 'next/dynamic';
import { useSearchParams, useRouter } from 'next/navigation';
import { FileText, Award, CalendarCheck } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Header from '@/components/Header';
import Footer from '@/components/Footer';

const FormInquiry = dynamic(() => import('./components/FormInquiry'), {
    loading: () => <div className="min-h-[400px] flex items-center justify-center"><div className="w-10 h-10 border-3 border-primary/25 border-t-primary rounded-full animate-spin" /></div>,
  });
const CeremonyInquiry = dynamic(() => import('./components/CeremonyInquiry'), {
  loading: () => <div className="min-h-[400px] flex items-center justify-center"><div className="w-10 h-10 border-3 border-primary/25 border-t-primary rounded-full animate-spin" /></div>,
  });
const ResultInquiry = dynamic(() => import('./components/ResultInquiry'), {
  loading: () => <div className="min-h-[400px] flex items-center justify-center"><div className="w-10 h-10 border-3 border-primary/25 border-t-primary rounded-full animate-spin" /></div>,
});

const tabs = [
  { id: 'form', label: 'الاستمارة', icon: FileText },
  { id: 'result', label: 'النتيجة', icon: Award },
  { id: 'ceremony', label: 'حضور الحفل', icon: CalendarCheck },
] as const;

function StatusContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const currentTab = searchParams.get('tab');

  useEffect(() => {
    if (!currentTab) router.replace('/status?tab=form');
  }, [currentTab, router]);

  if (!currentTab) {
    return (
      <div className="min-h-[400px] flex items-center justify-center">
        <div className="w-10 h-10 border-3 border-primary/25 border-t-primary rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: 'easeOut' }}
      className="max-w-3xl mx-auto px-4 pb-24 pt-4 relative z-10"
    >
      {/* Tabs */}
      <div className="flex justify-center mb-8">
        <nav className="w-full sm:w-auto grid grid-cols-3 sm:inline-flex items-center gap-1 bg-white rounded-2xl p-1 shadow-sm border border-outline-variant/10" role="tablist">
          {tabs.map((tab) => {
            const isActive = currentTab === tab.id;
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => router.push(`/status?tab=${tab.id}`)}
                role="tab"
                aria-selected={isActive}
                className={`relative flex items-center justify-center gap-1.5 px-3 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all duration-200
                  ${isActive
                    ? 'text-white'
                    : 'text-on-surface-variant/60 hover:text-on-surface hover:bg-surface-container-low'
                  }`}
              >
                {isActive && (
                  <motion.span
                    layoutId="tab-bg"
                    className="absolute inset-0 bg-primary rounded-xl shadow-sm"
                    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                  />
                )}
                <span className="relative z-10 flex items-center gap-1 sm:gap-2">
                  <Icon size={15} />
                  <span className="whitespace-nowrap">{tab.label}</span>
                </span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Content */}
      <div className="bg-white rounded-2xl border border-outline-variant/10 shadow-md overflow-hidden">
        <div className="p-6 sm:p-8">
          <AnimatePresence mode="wait">
            <motion.div
              key={currentTab}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
            >
              {currentTab === 'form' && <FormInquiry />}
              {currentTab === 'ceremony' && <CeremonyInquiry />}
              {currentTab === 'result' && <ResultInquiry />}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
    </motion.div>
  );
}

export default function StatusPage() {
  return (
    <div className="min-h-screen bg-surface font-cairo flex flex-col print:hidden" dir="rtl">
      <Header />
      <div className="flex-1">
        {/* Hero */}
        <section className="relative min-h-[32vh] md:min-h-[36vh] flex items-center overflow-hidden bg-primary">
          <div className="absolute inset-0 islamic-pattern z-0 opacity-[0.3]" />

          <motion.div
            initial={{ opacity: 0, scale: 1.05 }}
            animate={{ opacity: 0.4, scale: 1 }}
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
            <div className="absolute inset-0 bg-gradient-to-b from-black/10 via-transparent to-primary/60" />
          </motion.div>

          {/* Glow */}
          <div className="absolute -top-32 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-secondary-fixed/10 rounded-full blur-[120px] pointer-events-none z-[2]" />

          <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-primary/40 z-[3]" />
          <div className="absolute inset-x-0 bottom-0 h-24 bg-gradient-to-t from-surface to-transparent z-[4] pointer-events-none" />

          <div className="max-w-7xl mx-auto px-6 relative z-10 text-center w-full py-14">
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 text-white/80 text-xs font-bold mb-4"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-secondary-fixed" />
              بوابة الاستعلامات
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 16, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 0.6, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
              className="text-3xl sm:text-4xl md:text-5xl font-black text-secondary-fixed leading-[1.15]"
              style={{ fontFamily: "'Noto Serif', serif" }}
            >
              استعلامات المسابقة
            </motion.h1>

            <div className="flex items-center justify-center gap-2 mt-4 mb-4">
              <span className="w-6 h-0.5 rounded-full bg-secondary-fixed/30" />
              <span className="w-1.5 h-1.5 rounded-full bg-secondary-fixed/60" />
              <span className="w-6 h-0.5 rounded-full bg-secondary-fixed/30" />
            </div>

            <motion.p
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.3 }}
              className="text-white/70 text-sm max-w-lg mx-auto leading-relaxed font-semibold"
            >
              استعلم عن استمارة القبول، نتيجة الامتحان، أو حفل التكريم من خلال الرقم القومي
            </motion.p>
          </div>


        </section>

        {/* Content */}
        <section className="relative -mt-6">
          <Suspense fallback={
            <div className="min-h-[400px] flex items-center justify-center">
              <div className="w-10 h-10 border-3 border-primary/25 border-t-primary rounded-full animate-spin" />
            </div>
          }>
            <StatusContent />
          </Suspense>
        </section>
      </div>
      <Footer />
    </div>
  );
}
