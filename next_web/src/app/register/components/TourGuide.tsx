'use client';

import React from 'react';
import dynamic from 'next/dynamic';

const Joyride = dynamic(() => import('react-joyride').then(mod => mod.Joyride), { ssr: false });

// eslint-disable-next-line @typescript-eslint/no-explicit-any -- third-party Joyride render props
const CustomTooltip = (props: any) => {
  const {
    continuous, index, step, backProps, skipProps, primaryProps, tooltipProps, isLastStep,
  } = props;
  return (
    <div {...tooltipProps} className="bg-white rounded-3xl shadow-[0_20px_60px_-15px_rgba(0,0,0,0.1)] border border-slate-100 p-6 w-[320px] sm:w-[380px]" dir="rtl" style={{ fontFamily: 'var(--font-cairo), Cairo, sans-serif' }}>
      {step.title && <h3 className="text-xl font-black text-slate-900 mb-3">{step.title}</h3>}
      <div className="text-[15px] font-bold text-slate-600 mb-8 leading-relaxed">
        {step.content}
      </div>
      <div className="flex items-center justify-between border-t border-slate-100 pt-5">
        {index > 0 ? (
          <button {...backProps} className="text-slate-500 font-bold text-sm px-4 py-2.5 hover:text-slate-900 hover:bg-slate-50 rounded-xl transition-colors">
            السابق
          </button>
        ) : <div />}
        <div className="flex items-center gap-2">
          <button {...skipProps} className="text-slate-400 hover:text-red-500 font-bold text-sm px-3 py-2.5 hover:bg-red-50 rounded-xl transition-colors">
            تخطي
          </button>
          <button {...primaryProps} className="bg-slate-900 text-white font-bold text-sm px-6 py-2.5 rounded-xl hover:bg-slate-800 transition-colors shadow-lg">
            {continuous ? (isLastStep ? 'إنهاء' : 'التالي') : 'إغلاق'}
          </button>
        </div>
      </div>
    </div>
  );
};

interface TourGuideProps {
  tourKey: number;
  runTour: boolean;
  setRunTour: (run: boolean) => void;
  step: number;
}

export default function TourGuide({
  tourKey,
  runTour,
  setRunTour,
  step
}: TourGuideProps) {
  const steps = (() => {
    let s: { target: string; content: string; placement: 'center' | 'left' | 'bottom' | 'top' }[] = [];
    switch (step) {
      case 1:
        s = [
          { target: '.tour-start', content: 'مرحباً بك! هذا المرشد سيساعدك في تعبئة استمارة التسجيل بكل سهولة.', placement: 'center' },
          { target: '.tour-photo', content: 'انقر هنا لرفع صورتك الشخصية. تأكد أن تكون صورة واضحة ومناسبة.', placement: 'left' },
          { target: '.tour-name', content: 'في هذه الخانات، اكتب بياناتك الشخصية بدقة (الاسم رباعي ورقم الهاتف).', placement: 'bottom' },
          { target: '.tour-next', content: 'بعد ملء الحقول المطلوبة، اضغط هنا للانتقال للخطوة التالية.', placement: 'top' }
        ];
        break;
      case 2:
        s = [
          { target: '.tour-step2-info', content: 'هنا تدخل بياناتك الرسمية، مثل الرقم القومي المكون من 14 رقماً والعمر والنوع.', placement: 'bottom' },
          { target: '.tour-step2-cert', content: 'يرجى رفع صورة واضحة لشهادة الميلاد الخاصة بالطالب لتأكيد السن.', placement: 'bottom' },
          { target: '.tour-next', content: 'بعد الانتهاء، اضغط هنا للانتقال للمرحلة القادمة.', placement: 'top' }
        ];
        break;
      case 3:
        s = [
          { target: '.tour-step3-level', content: 'اختر مستوى المسابقة المناسب لمقدار حفظك الحالي من هذه القائمة.', placement: 'bottom' },
          { target: '.tour-step3-rewaya', content: 'إذا كان للمستوى المختار روايات أو قراءات متعددة، فستظهر خياراتها هنا للاختيار.', placement: 'bottom' },
          { target: '.tour-next', content: 'اضغط هنا للذهاب للخطوة الأخيرة.', placement: 'top' }
        ];
        break;
      case 4:
        s = [
          { target: '.tour-step4-memorizer', content: 'اكتب اسم المحفّظ أو الشيخ ورقم هاتفه للتنسيق اللاحق ومواعيد المتابعة.', placement: 'bottom' },
          { target: '.tour-step4-submit', content: 'أخيراً، قم بالموافقة على الإقرار، ثم اضغط على زر تأكيد وإرسال لإرسال استمارة التسجيل.', placement: 'top' }
        ];
        break;
      default:
        s = [];
    }
    return s.map(stepObj => ({ ...stepObj, disableBeacon: true }));
  })();

  return (
    <Joyride
      key={tourKey}
      steps={steps}
      run={runTour}
      continuous
      locale={{ back: 'السابق', close: 'إغلاق', last: 'إنهاء', next: 'التالي', skip: 'تخطي' }}
      tooltipComponent={CustomTooltip}
      options={{
        primaryColor: '#0f172a',
        zIndex: 1000,
      }}
      onEvent={(data: { status: string; type: string; action: string }) => {
        const { status, type, action } = data;
        if (
          status === 'finished' || 
          status === 'skipped' || 
          type === 'tour:end' || 
          action === 'close' || 
          action === 'skip'
        ) {
          setRunTour(false);
          localStorage.setItem('musapaka_tour_done', 'true');
        }
      }}
    />
  );
}
