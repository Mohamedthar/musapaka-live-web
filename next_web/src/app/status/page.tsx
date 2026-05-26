'use client';

import React, { Suspense, useEffect } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { FileText, Award, CalendarCheck } from 'lucide-react';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import FormInquiry from './components/FormInquiry';
import CeremonyInquiry from './components/CeremonyInquiry';
import ResultInquiry from './components/ResultInquiry';

const tabs = [
  { id: 'form', label: 'الاستمارة', short: 'استمارة', icon: FileText },
  { id: 'result', label: 'النتيجة', short: 'نتيجة', icon: Award },
  { id: 'ceremony', label: 'حفل التكريم', short: 'الحفل', icon: CalendarCheck },
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
        <div className="w-10 h-10 border-3 border-secondary/25 border-t-primary rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto px-4 pb-16 animate-fade-in">
      {/* Tab Navigation */}
      <div className="flex justify-center pt-8 pb-10">
        <div className="inline-flex bg-surface-container-low rounded-2xl p-1.5 gap-1">
          {tabs.map((tab) => {
            const isActive = currentTab === tab.id;
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => router.push(`/status?tab=${tab.id}`)}
                className={`relative flex items-center gap-1.5 sm:gap-2 px-3.5 sm:px-5 py-2.5 sm:py-3 rounded-xl text-xs sm:text-sm font-bold transition-all duration-200
                  ${isActive
                    ? 'bg-white text-primary shadow-sm'
                    : 'text-on-surface-variant hover:text-secondary'
                  }`}
              >
                <Icon size={16} />
                <span className="inline sm:hidden">{tab.short}</span>
                <span className="hidden sm:inline">{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Content */}
      <div className="min-h-[500px]">
        {currentTab === 'form' && <FormInquiry />}
        {currentTab === 'ceremony' && <CeremonyInquiry />}
        {currentTab === 'result' && <ResultInquiry />}
      </div>
    </div>
  );
}

export default function StatusPage() {
  return (
    <div className="min-h-screen bg-surface" dir="rtl">
      <Header />
      <Suspense fallback={
        <div className="min-h-[400px] flex items-center justify-center">
          <div className="w-10 h-10 border-3 border-secondary/25 border-t-primary rounded-full animate-spin" />
        </div>
      }>
        <StatusContent />
      </Suspense>
      <Footer />
    </div>
  );
}
