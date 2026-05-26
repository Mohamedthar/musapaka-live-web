'use client';

import React, { useState, useRef, useEffect } from 'react';
import { CreditCard, Award, Download, Printer, User, Layers, Hash, BookOpen, Search } from 'lucide-react';
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

const gradeConfigs: Record<string, { label: string; bg: string; border: string; text: string }> = {
  'ممتاز مع مرتبة الشرف': { label: 'ممتاز مع مرتبة الشرف', bg: 'bg-amber-50', border: 'border-amber-200', text: 'text-amber-700' },
  'ممتاز': { label: 'ممتاز', bg: 'bg-emerald-50', border: 'border-emerald-200', text: 'text-emerald-700' },
  'جيد جداً': { label: 'جيد جداً', bg: 'bg-blue-50', border: 'border-blue-200', text: 'text-blue-700' },
  'جيد': { label: 'جيد', bg: 'bg-sky-50', border: 'border-sky-200', text: 'text-sky-700' },
  'مقبول': { label: 'مقبول', bg: 'bg-gray-50', border: 'border-gray-200', text: 'text-gray-600' },
  'لم يجتز': { label: 'لم يجتز', bg: 'bg-red-50', border: 'border-red-200', text: 'text-red-600' },
};

export default function ResultInquiry() {
  const [nationalId, setNationalId] = useState('');
  const [isOpen, setIsOpen] = useState<boolean | null>(null);
  const [checkingStatus, setCheckingStatus] = useState(true);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [student, setStudent] = useState<StudentData | null>(null);
  const [level, setLevel] = useState<LevelData | null>(null);
  const [isDownloading, setIsDownloading] = useState(false);
  const ticketRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetch('/api/result').then(r => r.json()).then(d => setIsOpen(d.is_result_query_open)).catch(() => setIsOpen(false)).finally(() => setCheckingStatus(false));
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (nationalId.length !== 14) { setError('الرقم القومي يجب أن يتكون من 14 رقماً'); return; }
    setError(''); setLoading(true); setSearched(true); setStudent(null); setLevel(null);
    try {
      const r = await fetch('/api/result', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ nationalId }) });
      const d = await r.json();
      if (!r.ok) { setError(d.error || 'حدث خطأ'); return; }
      setStudent(d.student); setLevel(d.level);
    } catch { setError('فشل الاتصال بالخادم'); }
    finally { setLoading(false); }
  };

  const handleReset = () => { setStudent(null); setLevel(null); setSearched(false); setError(''); setNationalId(''); };

  // ── Loading state ──
  if (checkingStatus) {
    return <div className="flex items-center justify-center py-24"><div className="w-10 h-10 border-3 border-secondary/25 border-t-secondary rounded-full animate-spin" /></div>;
  }

  // ── Closed state ──
  if (isOpen === false) return <ClosedState type="result" />;

  // ── Score computation ──
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

  const { totalScore, maxScore, percentage, grade } = getScoreDetails();
  const gradeConf = gradeConfigs[grade];

  const downloadImage = async () => {
    setIsDownloading(true);
    const tid = toast.loading('جاري تجهيز وثيقة النتيجة...');
    try {
      const html2canvas = (await import('html2canvas-pro')).default;
      const el = document.getElementById('result-ticket');
      if (!el) { toast.error('لم يتم العثور على الوثيقة', { id: tid }); return; }
      const canvas = await html2canvas(el, { scale: 2, useCORS: true, backgroundColor: '#fff', logging: false, windowWidth: 850, windowHeight: el.scrollHeight + 100 });
      const link = document.createElement('a');
      link.href = canvas.toDataURL('image/png');
      link.download = `نتيجة_${student?.name?.replace(/\s+/g, '_') ?? 'طالب'}.png`;
      document.body.appendChild(link); link.click(); document.body.removeChild(link);
      toast.success('تم تحميل الوثيقة بنجاح', { id: tid });
    } catch { toast.error('فشل تحميل الصورة', { id: tid }); }
    finally { setIsDownloading(false); }
  };

  const print = () => window.print();

  // ── Result View ──
  if (student && level) {
    return (
      <div className="w-full animate-fade-in" dir="rtl">
        {/* Actions bar */}
        <div className="flex items-center justify-between mb-8 print:hidden">
          <button onClick={handleReset} className="flex items-center gap-2 text-sm font-bold text-gray-400 hover:text-gray-600 transition-colors px-4 py-2 rounded-xl hover:bg-gray-50">
            <span>→</span> بحث جديد
          </button>
          <div className="flex gap-2">
              <button onClick={print} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm font-bold transition-all">
              <Printer size={16} /> طباعة
            </button>
            <button onClick={downloadImage} disabled={isDownloading} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-secondary hover:bg-secondary-fixed-dim text-white text-sm font-bold transition-all shadow-sm">
              <Download size={16} /> {isDownloading ? 'جاري...' : 'تحميل'}
            </button>
          </div>
        </div>

        {/* Certificate */}
        <div id="result-ticket" className="bg-white rounded-3xl shadow-xl shadow-gray-100 overflow-hidden print:shadow-none print:rounded-none">
          {/* Top bar */}
          <div className="h-3 bg-gradient-to-r from-secondary via-secondary-fixed to-secondary" />

          <div className="p-6 sm:p-12">
            {/* Header */}
            <div className="text-center mb-10">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-amber-50 mb-3">
                <Award size={28} className="text-amber-500" />
              </div>
              <h2 className="text-2xl font-black text-gray-900">وثيقة نتيجة المتسابق</h2>
              <p className="text-sm text-gray-400 mt-1">مسابقة القرآن الكريم</p>
            </div>

            {/* Student info row */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4 mb-8">
              {[
                { label: 'الاسم', value: student.name, icon: <User size={14} /> },
                { label: 'كود المتسابق', value: student.student_code, icon: <Hash size={14} /> },
                { label: 'المستوى', value: `${student.level} - ${student.level_content}`, icon: <Layers size={14} /> },
                { label: 'الرواية', value: student.selected_rewaya ?? '-', icon: <BookOpen size={14} /> },
              ].map((item, i) => (
                <div key={i} className="bg-gray-50 rounded-2xl p-4 border border-gray-100">
                  <div className="flex items-center gap-1.5 text-gray-400 mb-1">{item.icon}<span className="text-xs font-bold">{item.label}</span></div>
                  <p className="text-sm font-bold text-gray-800">{item.value}</p>
                </div>
              ))}
            </div>

            {/* Grade badge */}
            <div className={`flex items-center justify-center mb-10`}>
              <div className={`inline-flex items-center gap-2 px-6 py-3 rounded-2xl border-2 ${gradeConf.border} ${gradeConf.bg}`}>
                <span className={`text-2xl font-black ${gradeConf.text}`}>{percentage.toFixed(1)}%</span>
                <span className="text-gray-300">|</span>
                <span className={`text-sm font-bold ${gradeConf.text}`}>{gradeConf.label}</span>
              </div>
            </div>

            {/* Scores table */}
            <div className="overflow-hidden rounded-2xl border border-gray-200">
              <table className="w-full text-sm">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="text-right py-3.5 px-4 font-bold text-gray-600">المعيار</th>
                    <th className="text-center py-3.5 px-4 font-bold text-gray-600">الدرجة</th>
                    <th className="text-center py-3.5 px-4 font-bold text-gray-600">الدرجة القصوى</th>
                    <th className="text-center py-3.5 px-4 font-bold text-gray-600">النسبة</th>
                  </tr>
                </thead>
                <tbody>
                  {[
                    { label: 'الدرجة الأساسية', score: student.score, max: level.total_points ?? 100, show: true },
                    { label: 'التلاوة والتجويد', score: student.rewaya_score, max: level.rewaya_max_score, show: level.has_rewaya },
                    { label: 'أحكام التجويد', score: student.tajweed_score, max: level.tajweed_max_score, show: level.has_tajweed },
                    { label: 'جمال الصوت والأداء', score: student.voice_score, max: level.voice_max_score, show: level.has_voice },
                    { label: 'تفسير ومعاني الكلمات', score: student.meaning_score, max: level.meaning_max_score, show: level.has_meaning },
                  ].filter(s => s.show).map((s, i) => (
                    <tr key={i} className="border-t border-gray-100">
                      <td className="py-3.5 px-4 font-bold text-gray-700">{s.label}</td>
                      <td className="text-center py-3.5 px-4 font-bold text-gray-800">{s.score ?? 0}</td>
                      <td className="text-center py-3.5 px-4 text-gray-400">{s.max}</td>
                      <td className="text-center py-3.5 px-4 font-bold text-gray-700">{((s.score ?? 0) / ((s.max ?? 1) > 0 ? (s.max ?? 1) : 1) * 100).toFixed(1)}%</td>
                    </tr>
                  ))}
                  {/* Total row */}
                  <tr className="border-t-2 border-gray-300 bg-gray-50/50">
                    <td className="py-4 px-4 font-black text-gray-900">المجموع الكلي</td>
                    <td className="text-center py-4 px-4 font-black text-gray-900 text-base">{totalScore}</td>
                    <td className="text-center py-4 px-4 font-bold text-gray-500">{maxScore}</td>
                    <td className="text-center py-4 px-4 font-black text-gray-900 text-base">{percentage.toFixed(1)}%</td>
                  </tr>
                </tbody>
              </table>
            </div>

            {/* Footer */}
            <div className="mt-8 pt-6 border-t border-gray-100 text-center">
              <p className="text-xs text-gray-400">هذه الوثيقة رسمية ومعتمدة من إدارة مسابقة القرآن الكريم</p>
              <p className="text-xs text-gray-300 mt-1">المشرف العام: أ/ مصطفى عبدالرحمن محمد سالم</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // ── Form View ──
  return (
    <div className="w-full">
      <div className="text-center mb-8">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-secondary/10 mb-4">
          <Award size={28} className="text-secondary" />
        </div>
        <h1 className="text-xl sm:text-3xl font-black text-primary mb-2">استعلام النتيجة وبيان الدرجات</h1>
        <p className="text-sm text-on-surface-variant max-w-md mx-auto leading-relaxed">
          أدخل الرقم القومي للمتسابق لمعرفة الدرجات التفصيلية والتقدير النهائي
        </p>
      </div>

      <form onSubmit={handleSubmit} className="max-w-md mx-auto">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 sm:p-8 space-y-5 sm:space-y-6">
          <div>
            <label className="block text-sm font-bold text-gray-700 mb-2">الرقم القومي للمتسابق <span className="text-red-400">*</span></label>
            <div className="relative">
              <input type="text" inputMode="numeric" maxLength={14}
                value={nationalId} onChange={e => { setNationalId(e.target.value.replace(/\D/g, '')); setSearched(false); setError(''); }}
                placeholder="أدخل الـ 14 رقماً"
                className={`w-full bg-gray-50 border-2 rounded-2xl py-3.5 pr-12 pl-4 text-sm font-semibold transition-all outline-none
                  ${searched && nationalId.length !== 14 ? 'border-red-200 bg-red-50/30' : 'border-gray-100 focus:border-secondary focus:bg-white focus:ring-4 focus:ring-secondary/5'}
                  text-gray-900 placeholder:text-gray-400`}
              />
              <CreditCard size={18} className={`absolute right-4 top-1/2 -translate-y-1/2 ${searched && nationalId.length !== 14 ? 'text-red-400' : 'text-gray-400'}`} />
            </div>
            {searched && nationalId.length !== 14 && <p className="text-red-500 text-xs font-bold mt-1.5 pr-1">الرقم القومي يجب أن يتكون من 14 رقماً</p>}
          </div>

          {error && <div className="bg-red-50 border border-red-100 rounded-2xl px-5 py-3.5"><p className="text-red-600 text-xs font-bold text-center">{error}</p></div>}

          <button type="submit" disabled={loading || nationalId.length !== 14}
            className="w-full flex items-center justify-center gap-2 sm:gap-2.5 py-3.5 sm:py-4 rounded-2xl font-bold text-white transition-all duration-300
              bg-gradient-to-r from-secondary to-secondary-fixed-dim hover:from-secondary-fixed-dim hover:to-secondary
              shadow-lg shadow-secondary/20 hover:shadow-xl hover:shadow-secondary/30 hover:-translate-y-0.5
              disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:translate-y-0">
            {loading ? <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : <><span>استعلام عن النتيجة</span><Search size={18} /></>}
          </button>
        </div>
      </form>
      <p className="text-center text-xs text-gray-400 mt-6">النتائج معتمدة من لجنة التحكيم ولا تقبل الطعون بعد إعلانها</p>
    </div>
  );
}
