'use client';

import React, { Suspense } from 'react';
import Image from 'next/image';
import { FileText, CalendarCheck, Award, Search, ArrowRight } from 'lucide-react';
import { useSearchParams, useRouter } from 'next/navigation';
import Header from '@/components/Header';
import FormInquiry from './components/FormInquiry';
import CeremonyInquiry from './components/CeremonyInquiry';
import ResultInquiry from './components/ResultInquiry';

function StatusContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const currentTab = searchParams.get('tab');

  const setTab = (tab: string | null) => {
    if (tab) {
      router.push(`/status?tab=${tab}`);
    } else {
      router.push('/status');
    }
  };

  if (!currentTab) {
    return (
      <div className="max-w-5xl mx-auto px-4 py-12 sm:py-16">
        <div className="text-center mb-12 animate-fade-in">
          <div className="flex justify-center mb-5">
            <div className="w-20 h-20 rounded-full overflow-hidden bg-white p-0.5 border border-[var(--border)] card-elevated">
              <Image 
                src="/logo_musapaka.jpeg" 
                alt="شعار مسابقة القرآن الكريم" 
                width={80} 
                height={80} 
                className="object-cover w-full h-full rounded-full"
              />
            </div>
          </div>

          <div className="badge mb-3 inline-flex">
            <Search size={11} />
            <span>بوابة الاستعلام الإلكتروني الموحدة</span>
          </div>

          <h1 className="text-3xl font-black text-[var(--primary)] mb-3">
            الاستعلام عن المتسابقين
          </h1>
          <p className="text-[var(--text-muted)] text-sm sm:text-base max-w-lg mx-auto leading-relaxed font-semibold">
            أهلاً بك في البوابة الموحدة لمسابقة أهل القرآن الكبرى. يرجى اختيار القسم المناسب أدناه للاستعلام الفوري باستخدام الرقم القومي.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8 max-w-4xl mx-auto animate-fade-in">
          <button
            onClick={() => setTab('form')}
            className="group card-elevated flex flex-col items-center text-center p-8 relative overflow-hidden"
          >
            <div className="absolute top-0 left-0 right-0 h-1 bg-[var(--primary)] opacity-0 group-hover:opacity-100 transition-opacity" />
            <div className="w-16 h-16 rounded-2xl bg-[var(--beige-light)] group-hover:bg-[var(--primary)] text-[var(--beige-dark)] group-hover:text-[var(--beige)] flex items-center justify-center mb-6 transition-all duration-300">
              <FileText size={28} />
            </div>
            <h3 className="text-lg font-black text-[var(--primary)] mb-2">
              حالة الاستمارة
            </h3>
            <p className="text-[var(--text-muted)] text-xs sm:text-sm font-semibold leading-relaxed mb-6">
              الاستعلام عن قبول استمارة التسجيل ومعرفة موعد ومكان اختبار المتسابق بالتفصيل.
            </p>
            <span className="mt-auto inline-flex items-center gap-1.5 text-xs font-bold text-[var(--beige-dark)] group-hover:text-[var(--primary)] transition-colors">
              <span>ابدأ الاستعلام</span>
              <ArrowRight size={14} className="rotate-180 transition-transform group-hover:-translate-x-1" />
            </span>
          </button>

          <button
            onClick={() => setTab('ceremony')}
            className="group card-elevated flex flex-col items-center text-center p-8 relative overflow-hidden"
          >
            <div className="absolute top-0 left-0 right-0 h-1 bg-[var(--primary)] opacity-0 group-hover:opacity-100 transition-opacity" />
            <div className="w-16 h-16 rounded-2xl bg-[var(--beige-light)] group-hover:bg-[var(--primary)] text-[var(--beige-dark)] group-hover:text-[var(--beige)] flex items-center justify-center mb-6 transition-all duration-300">
              <CalendarCheck size={28} />
            </div>
            <h3 className="text-lg font-black text-[var(--primary)] mb-2">
              حضور الحفل
            </h3>
            <p className="text-[var(--text-muted)] text-xs sm:text-sm font-semibold leading-relaxed mb-6">
              الاستعلام عن الموقف من حضور الحفل الختامي وتكريم أوائل المتسابقين وطباعة بطاقة الدعوة.
            </p>
            <span className="mt-auto inline-flex items-center gap-1.5 text-xs font-bold text-[var(--beige-dark)] group-hover:text-[var(--primary)] transition-colors">
              <span>ابدأ الاستعلام</span>
              <ArrowRight size={14} className="rotate-180 transition-transform group-hover:-translate-x-1" />
            </span>
          </button>

          <button
            onClick={() => setTab('result')}
            className="group card-elevated flex flex-col items-center text-center p-8 relative overflow-hidden"
          >
            <div className="absolute top-0 left-0 right-0 h-1 bg-[var(--primary)] opacity-0 group-hover:opacity-100 transition-opacity" />
            <div className="w-16 h-16 rounded-2xl bg-[var(--beige-light)] group-hover:bg-[var(--primary)] text-[var(--beige-dark)] group-hover:text-[var(--beige)] flex items-center justify-center mb-6 transition-all duration-300">
              <Award size={28} />
            </div>
            <h3 className="text-lg font-black text-[var(--primary)] mb-2">
              النتيجة النهائية
            </h3>
            <p className="text-[var(--text-muted)] text-xs sm:text-sm font-semibold leading-relaxed mb-6">
              الاستعلام عن درجات فروع الاختبار بالتفصيل، التقدير النهائي، وحفظ شهادة النتيجة الرسمية.
            </p>
            <span className="mt-auto inline-flex items-center gap-1.5 text-xs font-bold text-[var(--beige-dark)] group-hover:text-[var(--primary)] transition-colors">
              <span>ابدأ الاستعلام</span>
              <ArrowRight size={14} className="rotate-180 transition-transform group-hover:-translate-x-1" />
            </span>
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-10 sm:py-14">
      <div className="mb-6 animate-fade-in print:hidden">
        <button
          onClick={() => setTab(null)}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[var(--beige-light)] border border-[var(--border)] text-[var(--text-primary)] hover:bg-[var(--beige-light)] font-bold text-xs sm:text-sm transition-all"
        >
          <ArrowRight size={16} />
          <span>الرجوع لبوابة الاستعلام الموحدة</span>
        </button>
      </div>

      <div className="card-elevated p-6 sm:p-8 min-h-[350px] animate-fade-in">
        {currentTab === 'form' && <FormInquiry />}
        {currentTab === 'ceremony' && <CeremonyInquiry />}
        {currentTab === 'result' && <ResultInquiry />}
      </div>
    </div>
  );
}

export default function StatusPage() {
  return (
    <div className="min-h-screen bg-white" dir="rtl" style={{ fontFamily: 'var(--font-cairo), Cairo, sans-serif' }}>
      <Header />
      <main>
        <Suspense fallback={
          <div className="min-h-[400px] flex items-center justify-center">
            <div className="w-8 h-8 border-3 border-[var(--beige)]/25 border-t-[var(--primary)] rounded-full animate-spin"></div>
          </div>
        }>
          <StatusContent />
        </Suspense>
      </main>
    </div>
  );
}
