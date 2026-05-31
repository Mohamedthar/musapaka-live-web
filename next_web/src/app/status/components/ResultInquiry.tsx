'use client';

import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  CreditCard, Award, Download, Printer, User, Layers, Hash,
  Search, AlertTriangle, BarChart3
} from 'lucide-react';
import toast from 'react-hot-toast';
import ClosedState from '@/components/ClosedState';

interface StudentData {
  id: number; name: string; gender: string; level: string; level_content: string;
  student_code: string; profile_image_url: string | null; score: number | null;
  rewaya_score: number | null; selected_rewaya: string | null; tajweed_score: number | null;
  voice_score: number | null; meaning_score: number | null;
}
interface LevelData {
  content: string; total_points: number; has_rewaya: boolean; rewaya_max_score: number;
  has_tajweed: boolean; tajweed_max_score: number; has_voice: boolean; voice_max_score: number;
  has_meaning: boolean; meaning_max_score: number;
}

const gradeColors: Record<string, { label: string; bg: string; text: string; bar: string }> = {
  'ممتاز مع مرتبة الشرف': { label: 'ممتاز مع مرتبة الشرف', bg: 'bg-amber-100', text: 'text-amber-800', bar: 'bg-amber-500' },
  'ممتاز': { label: 'ممتاز', bg: 'bg-emerald-100', text: 'text-emerald-800', bar: 'bg-emerald-500' },
  'جيد جداً': { label: 'جيد جداً', bg: 'bg-blue-100', text: 'text-blue-800', bar: 'bg-blue-500' },
  'جيد': { label: 'جيد', bg: 'bg-sky-100', text: 'text-sky-800', bar: 'bg-sky-500' },
  'مقبول': { label: 'مقبول', bg: 'bg-gray-100', text: 'text-gray-600', bar: 'bg-gray-400' },
  'لم يجتز': { label: 'لم يجتز', bg: 'bg-red-100', text: 'text-red-700', bar: 'bg-red-500' },
};

function ScoreRow({ label, score, max, barColor }: { label: string; score: number | null; max: number | null; barColor: string }) {
  const pct = max && max > 0 ? Math.min(((score ?? 0) / max) * 100, 100) : 0;
  return (
    <div className="flex items-center gap-3 py-2.5">
      <span className="w-28 text-xs font-bold text-on-surface shrink-0">{label}</span>
      <div className="flex-1 h-2 bg-surface-container-low rounded-full overflow-hidden">
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${pct}%` }}
          transition={{ duration: 0.6, ease: 'easeOut' }}
          className={`h-full rounded-full ${barColor}`}
        />
      </div>
      <span className="w-24 text-left text-xs font-bold tabular-nums text-on-surface-variant/70">
        {score ?? 0}/{max ?? 0}
      </span>
    </div>
  );
}

export default function ResultInquiry() {
  const [nationalId, setNationalId] = useState('');
  const [isOpen, setIsOpen] = useState<boolean | null>(null);
  const [timing, setTiming] = useState<{ openDate?: string | null; closeDate?: string | null } | undefined>();
  const [checkingStatus, setCheckingStatus] = useState(true);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [notFound, setNotFound] = useState(false);
  const [student, setStudent] = useState<StudentData | null>(null);
  const [level, setLevel] = useState<LevelData | null>(null);
  const [isDownloading, setIsDownloading] = useState(false);
  const ticketRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetch('/api/result').then(r => r.json()).then(d => {
      setIsOpen(d.is_result_query_open);
      setTiming({ openDate: d.result_query_open_date, closeDate: d.result_query_close_date });
    }).catch(() => setIsOpen(false)).finally(() => setCheckingStatus(false));
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (nationalId.length !== 14) { setError('الرقم القومي يجب أن يتكون من 14 رقماً'); return; }
    setError(''); setNotFound(false); setLoading(true); setSearched(true); setStudent(null); setLevel(null);
    try {
      const r = await fetch('/api/result', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ nationalId }) });
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
      setStudent(d.student); setLevel(d.level);
    } catch { setError('فشل الاتصال بالخادم'); }
    finally { setLoading(false); }
  };

  const handleReset = () => { setStudent(null); setLevel(null); setSearched(false); setError(''); setNotFound(false); setNationalId(''); };

  if (checkingStatus) {
    return <div className="flex items-center justify-center py-20"><div className="w-8 h-8 border-3 border-primary/25 border-t-primary rounded-full animate-spin" /></div>;
  }

  if (isOpen === false) return <ClosedState type="result" timing={timing} />;

  const getScoreDetails = () => {
    if (!student || !level) return { totalScore: 0, maxScore: 100, percentage: 0, grade: 'لم يجتز' };
    let max = level.total_points ?? 100, total = student.score ?? 0;
    if (level.has_rewaya && (level.rewaya_max_score ?? 0) > 0) { max += level.rewaya_max_score!; total += student.rewaya_score ?? 0; }
    if (level.has_tajweed && (level.tajweed_max_score ?? 0) > 0) { max += level.tajweed_max_score!; total += student.tajweed_score ?? 0; }
    if (level.has_voice && (level.voice_max_score ?? 0) > 0) { max += level.voice_max_score!; total += student.voice_score ?? 0; }
    if (level.has_meaning && (level.meaning_max_score ?? 0) > 0) { max += level.meaning_max_score!; total += student.meaning_score ?? 0; }
    const pct = max > 0 ? (total / max) * 100 : 0;
    let grade = 'لم يجتز';
    if (pct >= 95) grade = 'ممتاز مع مرتبة الشرف';
    else if (pct >= 90) grade = 'ممتاز';
    else if (pct >= 80) grade = 'جيد جداً';
    else if (pct >= 70) grade = 'جيد';
    else if (pct >= 50) grade = 'مقبول';
    return { totalScore: total, maxScore: max, percentage: pct, grade };
  };

  const yieldToUi = () => new Promise(r => setTimeout(r, 0));

  const downloadImage = async () => {
    setIsDownloading(true);
    await yieldToUi();
    const tid = toast.loading('جاري التجهيز...');
    try {
      const html2canvas = (await import('html2canvas-pro')).default;
      const el = document.getElementById('result-ticket');
      if (!el) { toast.error('لم يتم العثور على الوثيقة', { id: tid }); return; }
      document.body.style.overflowX = 'hidden';
      const canvas = await html2canvas(el, { scale: 2, useCORS: true, backgroundColor: '#fff', logging: false, windowWidth: 850, windowHeight: el.scrollHeight + 100 });
      await yieldToUi();
      const link = document.createElement('a');
      link.href = canvas.toDataURL('image/png');
      link.download = `نتيجة_${student?.name?.replace(/\s+/g, '_') ?? 'طالب'}.png`;
      document.body.appendChild(link); link.click(); document.body.removeChild(link);
      toast.success('تم تحميل الوثيقة', { id: tid });
    } catch { toast.error('فشل تحميل الصورة', { id: tid }); }
    finally { document.body.style.overflowX = ''; setIsDownloading(false); }
  };

  // ─── Result View ───
  if (student && level) {
    const { totalScore, maxScore, percentage, grade } = getScoreDetails();
    const gc = gradeColors[grade];

    const scoreItems = [
      { label: 'الدرجة الأساسية', score: student.score, max: level.total_points ?? 100, show: true },
      { label: 'التلاوة والتجويد', score: student.rewaya_score, max: level.rewaya_max_score, show: level.has_rewaya },
      { label: 'أحكام التجويد', score: student.tajweed_score, max: level.tajweed_max_score, show: level.has_tajweed },
      { label: 'جمال الصوت والأداء', score: student.voice_score, max: level.voice_max_score, show: level.has_voice },
      { label: 'تفسير ومعاني الكلمات', score: student.meaning_score, max: level.meaning_max_score, show: level.has_meaning },
    ].filter(s => s.show);

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
              <div className="w-10 h-10 border-3 border-primary/25 border-t-primary rounded-full animate-spin mx-auto mb-4" />
              <p className="text-sm font-bold text-on-surface">جاري تجهيز الوثيقة</p>
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
        </div>

        {/* Certificate */}
        <div id="result-ticket" className="bg-white rounded-2xl border border-outline-variant/10 overflow-hidden print:border-none">
          <div className="p-6 sm:p-8">
            {/* Header */}
            <div className="text-center mb-6">
              <div className="w-12 h-12 rounded-xl bg-amber-50 flex items-center justify-center mx-auto mb-3">
                <Award size={22} className="text-amber-500" />
              </div>
              <h2 className="text-lg font-black text-primary">
                نتيجة المتسابق
              </h2>
              <p className="text-xs text-on-surface-variant/50 mt-1">مسابقة أهل القرآن الكبرى</p>
            </div>

            {/* Student info */}
            <div className="flex items-center gap-4 mb-6 p-4 bg-surface rounded-xl">
              {student.profile_image_url && (
                <div className="w-14 h-14 rounded-full overflow-hidden border-2 border-amber-100 shrink-0">
                  <img src={student.profile_image_url} alt="" className="w-full h-full object-cover" />
                </div>
              )}
              <div className="flex-1 min-w-0">
                <p className="font-black text-on-surface">{student.name}</p>
                <div className="flex flex-wrap gap-x-4 gap-y-0.5 mt-1 text-xs text-on-surface-variant/60 font-semibold">
                  <span>{student.student_code}</span>
                  <span>{student.level}{student.selected_rewaya ? ` - ${student.selected_rewaya}` : ''}</span>
                </div>
              </div>
            </div>

            {/* Grade */}
            <div className={`${gc.bg} rounded-xl p-5 text-center mb-6`}>
              <div className="text-3xl font-black tabular-nums mb-1">{percentage.toFixed(1)}%</div>
              <div className={`text-sm font-black ${gc.text}`}>{gc.label}</div>
            </div>

            {/* Score bars */}
            <div className="space-y-1 divide-y divide-outline-variant/5">
              {scoreItems.map((s, i) => (
                <ScoreRow key={i} label={s.label} score={s.score} max={s.max} barColor={gc.bar} />
              ))}
              <div className="flex items-center gap-3 pt-3">
                <span className="w-28 text-xs font-black text-primary shrink-0">المجموع الكلي</span>
                <div className="flex-1 h-3 bg-primary/10 rounded-full overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${Math.min(percentage, 100)}%` }}
                    transition={{ duration: 0.8, ease: 'easeOut' }}
                    className="h-full rounded-full bg-primary"
                  />
                </div>
                <span className="w-24 text-left text-xs font-black tabular-nums text-primary">
                  {totalScore}/{maxScore}
                </span>
              </div>
            </div>

            {/* Footer */}
            <div className="mt-6 pt-4 border-t border-outline-variant/10 text-center">
              <p className="text-xs text-on-surface-variant/40 font-semibold">المشرف العام: أ/ مصطفى عبدالرحمن محمد سالم</p>
            </div>
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
          <Award size={22} className="text-primary" />
        </div>
        <h1 className="text-xl sm:text-2xl font-black text-primary">
          استعلام النتيجة وبيان الدرجات
        </h1>
        <p className="text-sm sm:text-base text-on-surface-variant/70 mt-2 font-semibold">
          أدخل الرقم القومي للمتسابق لمعرفة الدرجات التفصيلية والتقدير النهائي
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
                  ${searched && nationalId.length !== 14
                    ? 'border-red-300 bg-red-50 text-red-900'
                    : 'border-outline-variant/30 bg-surface text-on-surface placeholder:text-on-surface-variant/30 hover:border-outline-variant/60 focus:border-primary focus:bg-white focus:shadow-sm focus:ring-2 focus:ring-primary/15'
                  }`}
              />
              <CreditCard size={16} className={`absolute right-4 top-1/2 -translate-y-1/2 ${searched && nationalId.length !== 14 ? 'text-red-400' : 'text-on-surface-variant/30'}`} />
            </div>
            <AnimatePresence>
              {searched && nationalId.length !== 14 && (
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

          <button type="submit" disabled={loading || nationalId.length !== 14}
            className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-bold text-sm text-white bg-primary hover:bg-primary/90 active:scale-[0.98] transition-all disabled:opacity-40 disabled:cursor-not-allowed disabled:active:scale-100 shadow-sm"
          >
            {loading ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <><Search size={16} /><span>استعلام عن النتيجة</span></>
            )}
          </button>
        </div>
      </form>

      <p className="text-center text-xs text-on-surface-variant/40 mt-6 font-semibold">
        النتائج معتمدة من لجنة التحكيم ولا تقبل الطعون بعد إعلانها
      </p>
    </motion.div>
  );
}
