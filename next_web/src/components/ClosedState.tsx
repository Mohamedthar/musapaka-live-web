'use client';

import { Lock, CalendarCheck, FileText, Award, Clock } from 'lucide-react';

const configs = {
  form: {
    icon: FileText,
    title: 'الاستعلام عن الاستمارة',
    desc: 'هذا القسم غير متاح حالياً. سيتم فتحه بعد انتهاء فترة التسجيل.',
  },
  result: {
    icon: Award,
    title: 'نتائج المسابقة',
    desc: 'النتائج لم تُعلن بعد. سيتم فتح القسم بعد انتهاء الاختبارات وإعلان النتائج الرسمية.',
  },
  ceremony: {
    icon: CalendarCheck,
    title: 'حفل التكريم',
    desc: 'هذا القسم غير متاح حالياً. سيتم فتحه بعد إعلان النتائج النهائية.',
  },
};

interface TimingInfo {
  openDate?: string | null;
  closeDate?: string | null;
}

function formatDate(dateStr: string | null | undefined): string {
  if (!dateStr) return '';
  try {
    const d = new Date(dateStr);
    return `${d.getFullYear()}/${(d.getMonth() + 1).toString().padStart(2, '0')}/${d.getDate().toString().padStart(2, '0')}`;
  } catch { return dateStr; }
}

export default function ClosedState({ type, timing }: { type: 'form' | 'result' | 'ceremony'; timing?: TimingInfo }) {
  const c = configs[type] || configs.result;
  const Icon = c.icon;

  const openDateStr = formatDate(timing?.openDate);
  const closeDateStr = formatDate(timing?.closeDate);
  const hasTiming = !!openDateStr || !!closeDateStr;

  return (
    <div className="w-full max-w-lg mx-auto" dir="rtl">
      <div className="text-center mb-8">
        <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary/15 to-primary/5 flex items-center justify-center mx-auto mb-4 shadow-sm border border-primary/10">
          <Icon size={22} className="text-primary" />
        </div>

        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-50/80 border border-amber-200/60 mb-4 shadow-sm">
          <Lock size={11} className="text-amber-500" />
          <span className="text-xs font-bold text-amber-700">مغلق</span>
        </div>

        <h3 className="text-xl sm:text-2xl font-black text-primary mb-2">{c.title}</h3>
        <p className="text-sm sm:text-base text-on-surface-variant/70 leading-relaxed font-semibold">{c.desc}</p>

        {hasTiming && (
          <div className="mt-5 bg-surface rounded-xl border border-outline-variant/10 shadow-sm p-4 text-right">
            <div className="flex items-center gap-1.5 mb-3">
              <Clock size={12} className="text-on-surface-variant/40" />
              <span className="text-xs font-bold text-on-surface-variant/60">المواعيد</span>
            </div>
            <div className="space-y-1.5 text-xs">
              {openDateStr && (
                <div className="flex justify-between items-center py-1">
                  <span className="font-semibold text-on-surface-variant/50">الفتح:</span>
                  <span className="font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md">{openDateStr}</span>
                </div>
              )}
              {closeDateStr && (
                <div className="flex justify-between items-center py-1">
                  <span className="font-semibold text-on-surface-variant/50">الإغلاق:</span>
                  <span className="font-bold text-red-600 bg-red-50 px-2 py-0.5 rounded-md">{closeDateStr}</span>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
