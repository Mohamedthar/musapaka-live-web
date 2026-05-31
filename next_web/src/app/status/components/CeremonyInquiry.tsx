'use client';

import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  CreditCard, CalendarCheck, User, Layers, Printer, Download,
  Search, MapPin, AlertTriangle, CheckCircle2, X, Hash
} from 'lucide-react';
import toast from 'react-hot-toast';
import ClosedState from '@/components/ClosedState';

interface CeremonyData {
  name: string; gender: string; level: string; level_content: string;
  ceremony_code: string; profile_image_url: string | null; is_eligible: boolean;
}

export default function CeremonyInquiry() {
  const [nationalId, setNationalId] = useState('');
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [notFound, setNotFound] = useState(false);
  const [data, setData] = useState<CeremonyData | null>(null);
  const [checkingStatus, setCheckingStatus] = useState(true);
  const [isOpen, setIsOpen] = useState<boolean | null>(null);
  const [timing, setTiming] = useState<{ openDate?: string | null; closeDate?: string | null } | undefined>();
  const [isDownloading, setIsDownloading] = useState(false);

  const idValid = nationalId.length === 14;

  useEffect(() => {
    fetch('/api/ceremony').then(r => r.json()).then(d => {
      setIsOpen(d.is_ceremony_query_open);
      setTiming({ openDate: d.ceremony_query_open_date, closeDate: d.ceremony_query_close_date });
    }).catch(() => setIsOpen(false)).finally(() => setCheckingStatus(false));
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idValid) { setError('الرقم القومي يجب أن يتكون من 14 رقماً'); return; }
    setError(''); setNotFound(false); setLoading(true); setSearched(true); setData(null);
    try {
      const r = await fetch('/api/ceremony', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ nationalId }) });
      const d = await r.json();
      if (!r.ok) {
        const msg = d.error || 'حدث خطأ';
        if (msg.includes('غير موجود') || msg.includes('يوجد') || msg.includes('العثور')) {
          setNotFound(true);
        } else {
          setError(msg);
        }
        return;
      }
      setData(d.student);
    } catch { setError('فشل الاتصال بالخادم'); }
    finally { setLoading(false); }
  };

  const handleReset = () => { setData(null); setSearched(false); setError(''); setNotFound(false); setNationalId(''); };

  const yieldToUi = () => new Promise(r => setTimeout(r, 0));

  const downloadImage = async () => {
    setIsDownloading(true);
    await yieldToUi();
    const tid = toast.loading('جاري التجهيز...');
    try {
      const html2canvas = (await import('html2canvas-pro')).default;
      const el = document.getElementById('ceremony-ticket');
      if (!el) { toast.error('لم يتم العثور على البطاقة', { id: tid }); return; }
      document.body.style.overflowX = 'hidden';
      const canvas = await html2canvas(el, { scale: 2, useCORS: true, backgroundColor: '#fff', logging: false, windowWidth: 850, windowHeight: el.scrollHeight + 100 });
      await yieldToUi();
      const link = document.createElement('a');
      link.href = canvas.toDataURL('image/png');
      link.download = `دعوة_${data?.name?.replace(/\s+/g, '_') ?? 'طالب'}.png`;
      document.body.appendChild(link); link.click(); document.body.removeChild(link);
      toast.success('تم تحميل البطاقة', { id: tid });
    } catch { toast.error('فشل تحميل الصورة', { id: tid }); }
    finally { document.body.style.overflowX = ''; setIsDownloading(false); }
  };

  if (checkingStatus) {
    return <div className="flex items-center justify-center py-20"><div className="w-8 h-8 border-3 border-primary/25 border-t-primary rounded-full animate-spin" /></div>;
  }

  if (isOpen === false) return <ClosedState type="ceremony" timing={timing} />;

  // ─── Invitation ───
  if (data) {
    const isEligible = data.is_eligible;

    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        className="w-full max-w-lg mx-auto"
        dir="rtl"
      >
        {isDownloading && (
          <div className="fixed inset-0 z-[99999] bg-black/50 flex items-center justify-center" style={{ backdropFilter: 'blur(4px)' }}>
            <div className="bg-white rounded-2xl px-8 py-6 shadow-xl text-center max-w-md">
              <div className="w-10 h-10 border-3 border-secondary/25 border-t-primary rounded-full animate-spin mx-auto mb-4" />
              <p className="text-sm font-bold text-on-surface">جاري تجهيز البطاقة</p>
              <p className="text-xs font-semibold text-on-surface-variant/60 mt-1">يرجى الانتظار قليلاً...</p>
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="flex items-center justify-between mb-5 print:hidden">
          <button onClick={handleReset}
            className="text-sm font-bold text-on-surface-variant/50 hover:text-secondary transition-colors">
            ← بحث جديد
          </button>
          {isEligible && (
            <div className="flex gap-2">
              <button onClick={() => window.print()}
                className="flex items-center gap-1.5 px-3 py-2 rounded-lg border border-outline-variant/20 text-xs font-bold text-on-surface-variant hover:bg-surface transition-colors">
                <Printer size={14} /> طباعة
              </button>
              <button onClick={downloadImage} disabled={isDownloading}
                className="flex items-center gap-1.5 px-3 py-2 rounded-lg bg-secondary text-white text-xs font-bold hover:bg-secondary/90 transition-colors disabled:opacity-50">
                <Download size={14} /> {isDownloading ? 'جاري...' : 'تحميل'}
              </button>
            </div>
          )}
        </div>

        {/* Card */}
        <div id="ceremony-ticket" className="bg-white rounded-2xl border border-outline-variant/10 overflow-hidden print:border-none">
          <div className="p-6 sm:p-8">
            {/* Header */}
            <div className="text-center mb-6">
              <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center mx-auto mb-3">
                <CalendarCheck size={22} className="text-emerald-500" />
              </div>
              <h2 className="text-lg font-black text-primary">
                بطاقة دعوة حفل التكريم
              </h2>
              <p className="text-xs text-on-surface-variant/50 mt-1">مسابقة أهل القرآن الكبرى</p>
            </div>

            {/* Profile + Info */}
            <div className="flex items-center gap-4 mb-6 p-4 bg-surface rounded-xl">
              {data.profile_image_url && (
                <div className="w-14 h-14 rounded-full overflow-hidden border-2 border-emerald-100 shrink-0">
                  <img src={data.profile_image_url} alt="" className="w-full h-full object-cover" />
                </div>
              )}
              <div className="flex-1 min-w-0">
                <p className="font-black text-on-surface">{data.name}</p>
                <div className="flex flex-wrap gap-x-4 gap-y-0.5 mt-1 text-xs text-on-surface-variant/60 font-semibold">
                  <span className="flex items-center gap-1"><Hash size={11} />{data.ceremony_code}</span>
                  <span>{data.level}</span>
                  <span>{data.gender === 'M' || data.gender === 'ذكر' ? 'ذكر' : 'أنثى'}</span>
                </div>
              </div>
            </div>

            {/* Eligibility */}
            <div className={`rounded-xl border-2 p-5 text-center mb-6 ${isEligible ? 'bg-emerald-50 border-emerald-200' : 'bg-red-50 border-red-200'}`}>
              {isEligible ? (
                <CheckCircle2 size={32} className="mx-auto text-emerald-500 mb-2" />
              ) : (
                <X size={32} className="mx-auto text-red-500 mb-2" />
              )}
              <p className={`text-lg font-black ${isEligible ? 'text-emerald-700' : 'text-red-600'}`}>
                {isEligible ? 'مؤهل للحضور' : 'غير مؤهل للحضور'}
              </p>
              {isEligible && (
                <p className="text-sm text-emerald-600 font-bold mt-1">يسرنا دعوتكم لحضور حفل التكريم الختامي</p>
              )}
            </div>

            {/* Congrats */}
            {isEligible && (
              <div className="mb-6 p-5 bg-primary/[0.03] border border-primary/[0.08] rounded-xl">
                <p className="text-sm font-black text-primary mb-1">تهنئة</p>
                <p className="text-xs font-semibold text-on-surface leading-relaxed">
                  لقد اجتزت اختبارات المسابقة بتفوق. يسعدنا حضورك حفل التكريم الختامي، سائلين المولى عز وجل أن يجعلك من أهل القرآن.
                </p>
              </div>
            )}

            {/* Supervisor */}
            <div className="text-center border-t border-outline-variant/10 pt-5">
              <p className="text-xs font-bold text-on-surface-variant/50">المشرف العام على المسابقة</p>
              <p className="text-sm font-black text-primary mt-0.5">أ/ مصطفى عبدالرحمن محمد سالم</p>
              <div className="flex items-center justify-center gap-1 mt-2 text-xs text-on-surface-variant/40">
                <MapPin size={11} />
                <span className="font-semibold">مقر اللجنة: مركز فاقوس - قرية الديدمون - شارع الشيخ - منزل المشرف العام</span>
              </div>
            </div>

            {/* Footer hint */}
            <p className="text-center text-xs text-on-surface-variant/30 mt-5 font-semibold">
              يرجى إحضار هذه البطاقة مطبوعة أو صورة منها يوم الحفل
            </p>
          </div>
        </div>
      </motion.div>
    );
  }

  // ─── Form ───
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.3, ease: 'easeOut' }}
      className="w-full max-w-lg mx-auto"
    >
      <div className="text-center mb-8">
        <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary/15 to-primary/5 flex items-center justify-center mx-auto mb-4 shadow-sm border border-primary/10">
          <CalendarCheck size={22} className="text-primary" />
        </div>
        <h1 className="text-xl sm:text-2xl font-black text-primary">
          استعلام حضور الحفل الختامي
        </h1>
        <p className="text-sm sm:text-base text-on-surface-variant/70 mt-2 font-semibold">
          أدخل الرقم القومي لمعرفة موقفك من حضور حفل التكريم
        </p>
      </div>

      <AnimatePresence>
        {notFound && (
          <motion.div
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            className="mb-6 p-4 bg-amber-50/80 border border-amber-200/60 rounded-xl text-center shadow-sm"
          >
            <AlertTriangle size={20} className="mx-auto text-amber-500 mb-2" />
            <p className="text-amber-800 font-bold text-sm mb-0.5">لم يتم العثور على المتسابق</p>
            <p className="text-amber-600 text-xs font-semibold">تأكد من صحة الرقم القومي المدخل</p>
          </motion.div>
        )}
      </AnimatePresence>

      <form onSubmit={handleSubmit} dir="rtl">
        <div className="space-y-5">
          <div>
            <label className="block text-sm font-bold text-on-surface mb-2">
              الرقم القومي
              <span className="text-red-400 mr-1">*</span>
            </label>
            <div className="relative">
              <input type="text" inputMode="numeric" maxLength={14}
                value={nationalId}
                onChange={e => { setNationalId(e.target.value.replace(/\D/g, '')); setSearched(false); setError(''); setNotFound(false); }}
                placeholder="أدخل الـ 14 رقماً"
                className={`block w-full min-w-0 border rounded-xl py-3 pr-11 pl-3 text-sm font-bold outline-none transition-all
                  ${searched && !idValid
                    ? 'border-red-300 bg-red-50 text-red-900'
                    : 'border-outline-variant/30 bg-surface text-on-surface placeholder:text-on-surface-variant/30 hover:border-outline-variant/60 focus:border-primary focus:bg-white focus:shadow-sm focus:ring-2 focus:ring-primary/15'
                  }`}
              />
              <CreditCard size={16} className={`absolute right-4 top-1/2 -translate-y-1/2 ${searched && !idValid ? 'text-red-400' : 'text-on-surface-variant/30'}`} />
            </div>
            <AnimatePresence>
              {searched && !idValid && (
                <motion.p
                  initial={{ opacity: 0, y: -4 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -4 }}
                  className="text-red-500 text-xs font-bold mt-1.5"
                >
                  الرقم القومي يجب أن يتكون من 14 رقماً
                </motion.p>
              )}
            </AnimatePresence>
          </div>

          <AnimatePresence>
            {error && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="bg-red-50/80 border border-red-200/60 rounded-xl px-4 py-3 shadow-sm"
              >
                <p className="text-red-600 text-xs font-bold text-center">{error}</p>
              </motion.div>
            )}
          </AnimatePresence>

          <button type="submit" disabled={loading || !idValid}
            className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-bold text-sm text-white bg-primary hover:bg-primary/90 active:scale-[0.98] transition-all disabled:opacity-40 disabled:cursor-not-allowed disabled:active:scale-100 shadow-sm"
          >
            {loading ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <><Search size={16} /><span>استخراج بطاقة الدعوة</span></>
            )}
          </button>
        </div>
      </form>

      <p className="text-center text-xs text-on-surface-variant/40 mt-6 font-semibold">
        يرجى إحضار البطاقة المطبوعة أو صورة منها يوم الحفل
      </p>
    </motion.div>
  );
}
