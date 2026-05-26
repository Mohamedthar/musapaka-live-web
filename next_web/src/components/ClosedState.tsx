import { Lock, Award, CalendarCheck, FileText } from 'lucide-react';

const configs = {
  form: { icon: FileText, title: 'الاستعلام عن الاستمارة', desc: 'قسم الاستعلام عن بيانات التسجيل غير متاح حالياً. سيتم فتحه بعد انتهاء فترة التسجيل.' },
  result: { icon: Award, title: 'نتائج المسابقة', desc: 'النتائج لم تُعلن بعد. سيتم فتح القسم بعد انتهاء الاختبارات وإعلان النتائج الرسمية.' },
  ceremony: { icon: CalendarCheck, title: 'حفل التكريم', desc: 'قسم الاستعلام عن حفل التكريم غير متاح حالياً. سيتم فتحه بعد إعلان النتائج النهائية.' },
};

export default function ClosedState({ type }: { type: 'form' | 'result' | 'ceremony' }) {
  const c = configs[type] || configs.result;
  const Icon = c.icon;

  return (
    <div className="w-full max-w-md mx-auto animate-fade-in" dir="rtl">
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        {/* Top accent bar */}
        <div className="h-1.5 bg-gradient-to-r from-secondary via-secondary-fixed to-secondary" />

        <div className="p-8 sm:p-10 text-center">
          {/* Icon */}
          <div className="w-18 h-18 mx-auto mb-5 rounded-2xl bg-secondary/10 flex items-center justify-center text-secondary">
            <Icon size={30} />
          </div>

          {/* Lock badge */}
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-gray-50 border border-gray-100 mb-4">
            <Lock size={12} className="text-gray-400" />
            <span className="text-xs font-bold text-on-surface-variant">مغلق مؤقتاً</span>
          </div>

          {/* Title */}
          <h3 className="text-lg font-black text-primary mb-3">{c.title}</h3>

          {/* Description */}
          <p className="text-sm text-on-surface-variant leading-relaxed">{c.desc}</p>

          {/* Hint */}
          <div className="mt-7 pt-6 border-t border-gray-50">
            <p className="text-xs text-gray-400">تابع الصفحة الرسمية لمعرفة مواعيد فتح الأقسام</p>
          </div>
        </div>
      </div>
    </div>
  );
}
