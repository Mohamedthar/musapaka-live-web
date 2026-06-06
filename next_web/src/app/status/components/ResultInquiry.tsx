'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CreditCard, Award, Search, AlertTriangle, Phone } from 'lucide-react';
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

export default function ResultInquiry() {
  const [nationalId, setNationalId] = useState('');
  const [phone, setPhone] = useState('');
  const [isOpen, setIsOpen] = useState<boolean | null>(null);
  const [timing, setTiming] = useState<{ openDate?: string | null; closeDate?: string | null } | undefined>();
  const [checkingStatus, setCheckingStatus] = useState(true);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [notFound, setNotFound] = useState(false);
  const [student, setStudent] = useState<StudentData | null>(null);
  const [level, setLevel] = useState<LevelData | null>(null);

  useEffect(() => {
    fetch('/api/result').then(r => r.json()).then(d => {
      setIsOpen(d.is_result_query_open);
      setTiming({ openDate: d.result_query_open_date, closeDate: d.result_query_close_date });
    }).catch(() => setIsOpen(false)).finally(() => setCheckingStatus(false));
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (nationalId.length !== 14) { setError('الرقم القومي يجب أن يتكون من 14 رقماً'); return; }
    if (!phone || phone.length < 10) { setError('رقم الهاتف مطلوب'); return; }
    setError(''); setNotFound(false); setLoading(true); setSearched(true); setStudent(null); setLevel(null);
    try {
      const r = await fetch('/api/result', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ nationalId, phone }) });
      const d = await r.json();
      if (!r.ok) {
        const msg = d.error || 'حدث خطأ';
        if (msg.includes('غير موجود') || msg.includes('يوجد') || msg.includes('العثور')) setNotFound(true);
        else setError(msg);
        return;
      }
      setStudent(d.student); setLevel(d.level);
    } catch { setError('فشل الاتصال بالخادم'); }
    finally { setLoading(false); }
  };

  const handleReset = () => { setStudent(null); setLevel(null); setSearched(false); setError(''); setNotFound(false); setNationalId(''); setPhone(''); };

  if (checkingStatus) {
    return <div className="flex items-center justify-center py-20"><div className="w-8 h-8 border-3 border-primary/25 border-t-primary rounded-full animate-spin" /></div>;
  }

  if (isOpen === false) return <ClosedState type="result" timing={timing} />;

  if (student && level) {
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

    const scoreItems = [
      { label: 'الدرجة الأساسية', score: student.score, max: level.total_points ?? 100, show: true },
      { label: `الرواية${student.selected_rewaya ? ` (${student.selected_rewaya})` : ''}`, score: student.rewaya_score, max: level.rewaya_max_score, show: level.has_rewaya && (level.rewaya_max_score ?? 0) > 0 },
      { label: 'التجويد', score: student.tajweed_score, max: level.tajweed_max_score, show: level.has_tajweed && (level.tajweed_max_score ?? 0) > 0 },
      { label: 'حسن الصوت', score: student.voice_score, max: level.voice_max_score, show: level.has_voice && (level.voice_max_score ?? 0) > 0 },
      { label: 'فهم المعاني والوقف', score: student.meaning_score, max: level.meaning_max_score, show: level.has_meaning && (level.meaning_max_score ?? 0) > 0 },
    ].filter(s => s.show);

    const gradeBg = pct >= 90 ? '#fef3c7' : pct >= 70 ? '#f8fafc' : '#fef2f2';
    const gradeText = pct >= 50 ? '#b45309' : '#dc2626';

    return (
      <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="w-full max-w-2xl mx-auto px-0" dir="rtl" style={{ fontFamily: 'Cairo, sans-serif' }}>

        <div className="flex justify-between items-center mb-5 print:hidden">
          <button onClick={handleReset} className="flex items-center gap-1.5 text-slate-600 hover:text-slate-900 font-bold text-xs transition-colors">
            <Search size={14} className="rotate-180" /> استعلام جديد
          </button>
        </div>

        {/* Name */}
        <div className="text-center mb-6">
          <div style={{ fontSize: '16pt', fontWeight: 700, color: '#0f172a', fontFamily: '"Cairo", sans-serif' }}>{student.name}</div>
          <div style={{ fontSize: '10pt', fontWeight: 400, color: '#64748b', fontFamily: '"Cairo", sans-serif', marginTop: '2pt' }}>
            {student.level}{student.selected_rewaya ? ` - ${student.selected_rewaya}` : ''}  ·  {student.student_code}
          </div>
        </div>

        {/* Score Table */}
        <table style={{ width: '100%', borderCollapse: 'collapse', border: '1pt solid #e2e8f0', borderRadius: '6pt', overflow: 'hidden' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8fafc' }}>
              <th style={{ padding: '8pt 12pt', fontSize: '11pt', fontWeight: 700, color: '#0f172a', fontFamily: '"Cairo", sans-serif', textAlign: 'right', borderBottom: '1pt solid #e2e8f0' }}>المادة</th>
              <th style={{ padding: '8pt 12pt', fontSize: '11pt', fontWeight: 700, color: '#0f172a', fontFamily: '"Cairo", sans-serif', textAlign: 'center', borderBottom: '1pt solid #e2e8f0' }}>الدرجة</th>
            </tr>
          </thead>
          <tbody>
            {scoreItems.map((s, i) => (
              <tr key={i} style={{ backgroundColor: i % 2 === 0 ? 'white' : '#fafafa' }}>
                <td style={{ padding: '7pt 12pt', fontSize: '10pt', fontWeight: 400, color: '#0f172a', fontFamily: '"Cairo", sans-serif', textAlign: 'right', borderBottom: i < scoreItems.length - 1 ? '1pt solid #e2e8f0' : 'none' }}>{s.label}</td>
                <td style={{ padding: '7pt 12pt', fontSize: '10pt', fontWeight: 700, color: '#0f172a', fontFamily: 'monospace', textAlign: 'center', borderBottom: i < scoreItems.length - 1 ? '1pt solid #e2e8f0' : 'none' }}>{s.score ?? 0} / {s.max ?? 0}</td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr style={{ backgroundColor: '#f1f5f9' }}>
              <td style={{ padding: '8pt 12pt', fontSize: '11pt', fontWeight: 700, color: '#0f172a', fontFamily: '"Cairo", sans-serif', textAlign: 'right', borderTop: '2pt solid #0f172a' }}>المجموع الكلي</td>
              <td style={{ padding: '8pt 12pt', fontSize: '11pt', fontWeight: 700, color: '#0f172a', fontFamily: 'monospace', textAlign: 'center', borderTop: '2pt solid #0f172a' }}>{total} / {max} ({pct.toFixed(1)}%)</td>
            </tr>
          </tfoot>
        </table>

        {/* Grade */}
        <div className="text-center mt-4">
          <span style={{ fontSize: '11pt', fontWeight: 700, color: gradeText, fontFamily: '"Cairo", sans-serif', backgroundColor: gradeBg, padding: '4pt 12pt', borderRadius: '4pt' }}>{grade}</span>
        </div>

        <p className="text-center text-xs text-slate-400 mt-5 font-semibold">النتائج معتمدة من لجنة التحكيم</p>
      </motion.div>
    );
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }} className="w-full max-w-lg mx-auto">
      <div className="text-center mb-8">
        <div className="w-12 h-12 rounded-xl bg-amber-50 flex items-center justify-center mx-auto mb-4">
          <Award size={22} className="text-amber-500" />
        </div>
        <h1 className="text-xl sm:text-2xl font-black text-on-surface">استعلام النتيجة وبيان الدرجات</h1>
        <p className="text-sm sm:text-base text-on-surface-variant/70 mt-2 font-semibold">أدخل الرقم القومي للمتسابق لمعرفة الدرجات التفصيلية والتقدير النهائي</p>
      </div>
      <AnimatePresence>
        {notFound && (
          <motion.div initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} className="mb-6 p-4 bg-amber-50/80 border border-amber-200/60 rounded-xl text-center shadow-sm">
            <AlertTriangle size={20} className="mx-auto text-amber-500 mb-2" />
            <p className="text-amber-800 font-bold text-sm mb-0.5">لم يتم العثور على المتسابق</p>
            <p className="text-amber-600 text-xs font-semibold">تأكد من صحة الرقم القومي المدخل</p>
          </motion.div>
        )}
      </AnimatePresence>
      <form onSubmit={handleSubmit} dir="rtl">
        <div className="space-y-5">
          <div>
            <label className="block text-sm font-bold text-on-surface mb-2">الرقم القومي<span className="text-red-400 mr-1">*</span></label>
            <div className="relative">
              <input type="text" inputMode="numeric" maxLength={14} value={nationalId}
                onChange={e => { setNationalId(e.target.value.replace(/\D/g, '')); setSearched(false); setError(''); setNotFound(false); }}
                placeholder="أدخل الـ 14 رقماً"
                className={`block w-full border rounded-xl py-3 pr-11 pl-3 text-sm font-bold outline-none transition-all ${searched && nationalId.length !== 14 ? 'border-red-300 bg-red-50 text-red-900' : 'border-outline-variant/30 bg-surface text-on-surface placeholder:text-on-surface-variant/30 hover:border-outline-variant/60 focus:border-primary focus:bg-white focus:shadow-sm focus:ring-2 focus:ring-primary/15'}`} />
              <CreditCard size={16} className={`absolute right-4 top-1/2 -translate-y-1/2 ${searched && nationalId.length !== 14 ? 'text-red-400' : 'text-on-surface-variant/30'}`} />
            </div>
            <AnimatePresence>
              {searched && nationalId.length !== 14 && <motion.p initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -4 }} className="text-red-500 text-xs font-bold mt-1.5">الرقم القومي يجب أن يتكون من 14 رقماً</motion.p>}
            </AnimatePresence>
          </div>
          <div>
            <label className="block text-sm font-bold text-on-surface mb-2">رقم الهاتف<span className="text-red-400 mr-1">*</span></label>
            <div className="relative">
              <input type="text" inputMode="tel" maxLength={11} value={phone}
                onChange={e => { setPhone(e.target.value.replace(/\D/g, '')); setSearched(false); setError(''); }}
                placeholder="01xxxxxxxxx"
                className="block w-full border rounded-xl py-3 pr-11 pl-3 text-sm font-bold outline-none transition-all border-outline-variant/30 bg-surface text-on-surface placeholder:text-on-surface-variant/30 hover:border-outline-variant/60 focus:border-primary focus:bg-white focus:shadow-sm focus:ring-2 focus:ring-primary/15" />
              <Phone size={16} className="absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant/30" />
            </div>
          </div>
          <AnimatePresence>
            {error && <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-red-50/80 border border-red-200/60 rounded-xl px-4 py-3 shadow-sm"><p className="text-red-600 text-xs font-bold text-center">{error}</p></motion.div>}
          </AnimatePresence>
          <button type="submit" disabled={loading || nationalId.length !== 14 || !phone} className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-bold text-sm text-white bg-primary hover:bg-primary/90 active:scale-[0.98] transition-all disabled:opacity-40 disabled:cursor-not-allowed shadow-sm">
            {loading ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : <><Search size={16} /><span>استعلام عن النتيجة</span></>}
          </button>
        </div>
      </form>
      <p className="text-center text-xs text-on-surface-variant/40 mt-6 font-semibold">النتائج معتمدة من لجنة التحكيم ولا تقبل الطعون بعد إعلانها</p>
    </motion.div>
  );
}
