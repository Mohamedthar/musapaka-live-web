'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  CreditCard, CalendarCheck, User, Search, AlertTriangle, Download, X, Layers, FileText, Hash, Sparkles
} from 'lucide-react';
import toast from 'react-hot-toast';
import ClosedState from '@/components/ClosedState';
import confetti from 'canvas-confetti';

interface CeremonyData {
  name: string; level: string; level_content: string;
  ceremony_code: string; profile_image_url: string | null;
  is_eligible: boolean; percentage: number;
  total_score: number; max_score: number;
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
  const [isCapturing, setIsCapturing] = useState(false);
  const idValid = nationalId.length === 14;

  useEffect(() => {
    fetch('/api/ceremony').then(r => r.json()).then(d => {
      setIsOpen(d.is_ceremony_query_open);
      setTiming({ openDate: d.ceremony_query_open_date, closeDate: d.ceremony_query_close_date });
    }).catch(() => setIsOpen(false)).finally(() => setCheckingStatus(false));
  }, []);

  useEffect(() => {
    if (data?.is_eligible) {
      const defaults = { spread: 360, ticks: 100, gravity: 0.7, decay: 0.94, startVelocity: 30, colors: ['#f59e0b', '#0f172a', '#16a34a', '#eab308', '#dc2626'] };
      const shoot = () => {
        confetti({ ...defaults, particleCount: 50, origin: { x: Math.random(), y: Math.random() * 0.5 } });
        confetti({ ...defaults, particleCount: 50, origin: { x: Math.random(), y: Math.random() * 0.5 } });
      };
      shoot();
      setTimeout(shoot, 200);
      setTimeout(shoot, 400);
      setTimeout(shoot, 600);
      setTimeout(shoot, 800);
      const interval = setInterval(shoot, 1200);
      const stopTimer = setTimeout(() => clearInterval(interval), 8000);
      return () => { clearInterval(interval); clearTimeout(stopTimer); };
    }
  }, [data?.is_eligible]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idValid) { setError('الرقم القومي يجب أن يتكون من 14 رقماً'); return; }
    setError(''); setNotFound(false); setLoading(true); setSearched(true); setData(null);
    try {
      const r = await fetch('/api/ceremony', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ nationalId }) });
      const d = await r.json();
      if (!r.ok) {
        const msg = d.error || 'حدث خطأ';
        if (msg.includes('غير موجود') || msg.includes('يوجد') || msg.includes('العثور')) setNotFound(true);
        else setError(msg);
        return;
      }
      setData(d.student);
    } catch { setError('فشل الاتصال بالخادم'); }
    finally { setLoading(false); }
  };

  const handleReset = () => { setData(null); setSearched(false); setError(''); setNotFound(false); setNationalId(''); };


  const captureTicket = async () => {
    const el = document.getElementById('ceremony-ticket');
    if (!el) return null;
    const html2canvas = (await import('html2canvas-pro')).default;
    const canvas = await html2canvas(el, {
      scale: 2, useCORS: true, backgroundColor: '#ffffff', logging: false,
      windowWidth: 850, windowHeight: el.scrollHeight + 100,
      onclone: (clonedDoc) => {
        const clonedEl = clonedDoc.getElementById('ceremony-ticket');
        if (!clonedEl) return;
        clonedEl.style.maxWidth = '520pt';
        clonedEl.style.background = 'white';
        let parent: HTMLElement | null = clonedEl.parentElement;
        while (parent && parent !== clonedDoc.body) {
          parent.style.display = 'block';
          parent.style.height = 'auto';
          parent.style.overflow = 'visible';
          parent = parent.parentElement;
        }
      },
    });
    return canvas;
  };

  const handleDownloadImage = async () => {
    setIsCapturing(true);
    const toastId = toast.loading('جاري تجهيز البطاقة...');
    try {
      const canvas = await captureTicket();
      if (!canvas) { toast.error('البطاقة غير موجودة', { id: toastId }); return; }
      const filename = `بطاقة_حفل_${data?.name?.replace(/\s+/g, '_') ?? 'طالب'}.jpg`;
      const dataUrl = canvas.toDataURL('image/jpeg', 0.85);
      const link = document.createElement('a');
      link.href = dataUrl;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      toast.success('تم تحميل الملف', { id: toastId, duration: 4000 });
    } catch { toast.error('فشل تحميل الصورة', { id: toastId }); }
    finally { setIsCapturing(false); }
  };

  const handleDownloadPdf = async () => {
    setIsCapturing(true);
    const toastId = toast.loading('جاري تجهيز ملف PDF...');
    try {
      const canvas = await captureTicket();
      if (!canvas) { toast.error('البطاقة غير موجودة', { id: toastId }); return; }
      const { default: jsPDF } = await import('jspdf');
      const imgData = canvas.toDataURL('image/jpeg', 0.92);
      const pdf = new jsPDF('p', 'mm', 'a4');
      const pdfWidth = pdf.internal.pageSize.getWidth();
      const pdfHeight = pdf.internal.pageSize.getHeight();
      const imgWidth = canvas.width / 2;
      const imgHeight = canvas.height / 2;
      const scale = Math.min(pdfWidth / imgWidth, pdfHeight / imgHeight);
      const w = imgWidth * scale;
      const h = imgHeight * scale;
      const x = (pdfWidth - w) / 2;
      const y = (pdfHeight - h) / 2;
      pdf.addImage(imgData, 'JPEG', x, y, w, h);
      const pdfBlob = pdf.output('blob');
      const pdfUrl = URL.createObjectURL(pdfBlob);
      const link = document.createElement('a');
      link.href = pdfUrl;
      link.download = `بطاقة_حفل_${data?.name?.replace(/\s+/g, '_') ?? 'طالب'}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      setTimeout(() => URL.revokeObjectURL(pdfUrl), 1000);

      toast.success('تم تحميل الملف', { id: toastId });
    } catch { toast.error('فشل تحميل PDF', { id: toastId }); }
    finally { setIsCapturing(false); }
  };

  const decorations = useMemo(() => {
    let seed = 42;
    const rand = () => {
      seed = (seed * 16807) % 2147483647;
      return (seed - 1) / 2147483646;
    };

    const groups: { key: string; emoji: string; count: number; baseDur: number; baseSize: number; sizeRange: number }[] = [
      { key: 'a', emoji: '✨', count: 20, baseDur: 1.5, baseSize: 14, sizeRange: 16 },
      { key: 'b', emoji: '🎉', count: 12, baseDur: 1.8, baseSize: 18, sizeRange: 20 },
      { key: 'c', emoji: '⭐', count: 12, baseDur: 2.0, baseSize: 16, sizeRange: 18 },
      { key: 'd', emoji: '🎊', count: 10, baseDur: 1.5, baseSize: 15, sizeRange: 18 },
      { key: 'e', emoji: '💫', count: 8,  baseDur: 1.8, baseSize: 12, sizeRange: 14 },
    ];

    return groups.flatMap((g, gi) =>
      Array.from({ length: g.count }, (_, i) => ({
        key: `${g.key}-${i}`,
        emoji: g.emoji,
        left: rand() * 100,
        top: -10 - rand() * 20,
        delay: i * (0.15 + gi * 0.02),
        duration: g.baseDur + rand() * 1.5,
        fontSize: g.baseSize + rand() * g.sizeRange,
      }))
    );
  }, []);

  if (checkingStatus) {
    return <div className="flex items-center justify-center py-20"><div className="w-8 h-8 border-3 border-primary/25 border-t-primary rounded-full animate-spin" /></div>;
  }

  if (isOpen === false) return <ClosedState type="ceremony" timing={timing} />;

  if (data) {
    const isEligible = data.is_eligible;

    return (
      <>
        <style dangerouslySetInnerHTML={{ __html: `
          #ceremony-ticket-wrapper { display: none; }
          @media print {
            #ceremony-ticket-wrapper { display: block !important; }
          }
        `}} />
        {isCapturing && (
          <div className="fixed inset-0 z-[99999] bg-black/50 flex items-center justify-center" style={{ backdropFilter: 'blur(4px)' }}>
            <div className="bg-white rounded-2xl px-8 py-6 shadow-xl text-center max-w-md">
              <div className="w-10 h-10 border-3 border-slate-300 border-t-slate-800 rounded-full animate-spin mx-auto mb-4" />
              <p className="text-sm font-bold text-slate-800">جاري تجهيز البطاقة</p>
              <p className="text-xs font-semibold text-slate-500 mt-1">يرجى الانتظار قليلاً...</p>
            </div>
          </div>
        )}

        {isEligible && (
          /* Falling decorations — full page */
          <div className="fixed inset-0 pointer-events-none overflow-hidden z-0">
            {decorations.map((d) => (
              <div key={d.key} className="absolute text-lg animate-fall" style={{
                left: `${d.left}%`,
                top: `${d.top}%`,
                animationDelay: `${d.delay}s`,
                animationDuration: `${d.duration}s`,
                fontSize: `${d.fontSize}px`,
              }}>{d.emoji}</div>
            ))}
          </div>
        )}

        <motion.div initial={{ opacity: 0, y: 20, scale: 0.97 }} animate={{ opacity: 1, y: 0, scale: 1 }} transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }} className="w-full max-w-md mx-auto px-3 sm:px-0 print:hidden" dir="rtl" style={{ fontFamily: 'Cairo, sans-serif' }}>

          {isEligible ? (
            <>
              {/* Success Icon */}
              <div className="text-center mb-5 relative z-10">
                <div className="relative inline-flex mb-3">
                  <div className="w-16 h-16 rounded-full flex items-center justify-center bg-gradient-to-br from-amber-100 to-green-50 shadow-inner">
                    <Sparkles size={32} className="text-amber-500" style={{ filter: 'drop-shadow(0 1pt 2pt rgba(245,158,11,0.3))' }} />
                  </div>
                  <div className="absolute -top-1 -left-1 text-lg" style={{ filter: 'drop-shadow(0 1pt 1pt rgba(0,0,0,0.15))' }}>🎉</div>
                  <div className="absolute -top-1 -right-1 text-lg" style={{ filter: 'drop-shadow(0 1pt 1pt rgba(0,0,0,0.15))' }}>🎊</div>
                </div>
                <h2 className="text-xl font-black text-slate-800 mb-1">مبروك! أنت مؤهل للحضور</h2>
                <p className="text-sm font-bold text-slate-500 leading-relaxed">يمكنك الآن تحميل بطاقة الدعوة كصورة أو طباعتها.</p>
              </div>

          {/* Action Buttons */}
          <div className="flex flex-col sm:flex-row gap-3 mb-6">
            <button onClick={handleDownloadImage} disabled={isCapturing}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-slate-800 hover:bg-slate-900 disabled:bg-slate-500 text-white text-sm font-bold active:scale-95 transition-all shadow-sm cursor-pointer">
              <Download size={16} /> {isCapturing ? 'جاري...' : 'حفظ كصورة'}
            </button>
            <button onClick={handleDownloadPdf} disabled={isCapturing}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-slate-700 hover:bg-slate-800 disabled:bg-slate-500 text-white text-sm font-bold active:scale-95 transition-all shadow-sm cursor-pointer">
              <Download size={16} /> {isCapturing ? 'جاري...' : 'حفظ PDF'}
            </button>
          </div>
            </>
          ) : (
            <>
              {/* Failure message */}
              <div className="text-center mb-6">
                <div className="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-3 bg-red-50">
                  <X size={36} className="text-red-500" />
                </div>
                <h2 className="text-xl font-black text-slate-800 mb-2">نأسف، أنت غير مؤهل للحضور</h2>
                <p className="text-sm font-bold text-slate-500 leading-relaxed">
                  لم تحقق النسبة المطلوبة لحضور حفل التكريم.
                </p>
              </div>
            </>
          )}

          <div className="text-center mb-5">
            <button onClick={handleReset} className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-800 transition-colors cursor-pointer">
              <Search size={14} className="rotate-180" /> استعلام جديد
            </button>
          </div>
        </motion.div>

        {isEligible && (
        <div id="ceremony-ticket-wrapper">
        <div id="ceremony-ticket" className="bg-white mx-auto" style={{ maxWidth: '520pt', border: '1pt solid #e2e8f0', borderRadius: '8pt', overflow: 'hidden' }}>
          <div style={{ padding: '10pt 14pt' }}>

            {/* Header row */}
            <div style={{ paddingBottom: '5pt', borderBottom: '1.5pt solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8pt' }}>
              <div style={{ flex: 1 }}>
                <div style={{ color: '#0f172a', fontSize: '11pt', fontWeight: 700, fontFamily: '"Cairo", sans-serif' }}>بطاقة دعوة حفل التكريم</div>
                <div style={{ color: '#b45309', fontSize: '8pt', fontWeight: 700, marginTop: '1pt', fontFamily: '"Cairo", sans-serif' }}>مسابقة أهل القرآن الكبرى</div>
              </div>
              <div style={{ width: '28pt', height: '28pt', borderRadius: '50%', overflow: 'hidden', flexShrink: 0, marginRight: '8pt' }}>
                <img src="/logo_musapaka.jpeg" alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              </div>
            </div>

            {/* Unified row: all data on right, photo on left */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '10pt', border: '1pt solid #e2e8f0', borderRadius: '6pt', padding: '8pt 10pt', backgroundColor: '#fafafa', marginBottom: '8pt' }}>
              {/* All text data → right side */}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4pt', marginBottom: '2pt' }}>
                  <User size={10} color="#64748b" />
                  <span style={{ fontSize: '10pt', fontWeight: 700, color: '#0f172a', fontFamily: '"Cairo", sans-serif' }}>{data.name}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4pt', marginBottom: '2pt' }}>
                  <Layers size={10} color="#64748b" />
                  <span style={{ fontSize: '8pt', fontWeight: 400, color: '#475569', fontFamily: '"Cairo", sans-serif' }}>{data.level}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4pt', marginBottom: '2pt' }}>
                  <FileText size={10} color="#64748b" />
                  <span style={{ fontSize: '8pt', fontWeight: 400, color: '#475569', fontFamily: '"Cairo", sans-serif' }}>{data.level_content}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4pt' }}>
                  <Hash size={10} color="#b45309" />
                  <span style={{ fontSize: '8pt', fontWeight: 400, color: '#b45309', fontFamily: '"Cairo", sans-serif', direction: 'ltr', textAlign: 'right' }}>{data.ceremony_code}</span>
                </div>
              </div>

              {/* Photo → left side */}
              {data.profile_image_url ? (
                <div style={{ width: '44pt', height: '44pt', borderRadius: '50%', overflow: 'hidden', border: '2pt solid #f59e0b', flexShrink: 0 }}>
                  <img src={data.profile_image_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
              ) : (
                <div style={{ width: '44pt', height: '44pt', borderRadius: '50%', backgroundColor: '#f1f5f9', border: '2pt solid #f59e0b', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <User size={20} color="#94a3b8" />
                </div>
              )}
            </div>

            {/* Supervisor */}
            <div style={{ textAlign: 'center', paddingTop: '6pt', borderTop: '1pt solid #e2e8f0' }}>
              <div style={{ fontSize: '7pt', fontWeight: 700, color: '#b45309', fontFamily: '"Cairo", sans-serif' }}>المشرف العام على المسابقة</div>
              <div style={{ fontSize: '9pt', fontWeight: 700, color: '#0f172a', fontFamily: '"Cairo", sans-serif', marginTop: '1pt' }}>أ/ مصطفى عبدالرحمن محمد سالم</div>
            </div>

          </div>
        </div>
        </div>
        )}

        {/* Footer hint - only for eligible */}
        {isEligible && (
        <p className="text-center text-xs text-slate-400 mt-5 font-semibold print:hidden">
          يرجى الاحتفاظ بالبطاقة كصورة أو طباعتها للدخول بها إلى الحفل
        </p>
        )}
      </>
    );
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }} className="w-full max-w-lg mx-auto">
      <div className="text-center mb-8">
        <div className="w-12 h-12 rounded-xl bg-amber-50 flex items-center justify-center mx-auto mb-4">
          <CalendarCheck size={22} className="text-amber-500" />
        </div>
        <h1 className="text-xl sm:text-2xl font-black text-on-surface">استعلام حضور الحفل الختامي</h1>
        <p className="text-sm sm:text-base text-on-surface-variant/70 mt-2 font-semibold">أدخل الرقم القومي لمعرفة موقفك من حضور حفل التكريم</p>
      </div>
      <AnimatePresence>
        {notFound && (
          <motion.div initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} className="mb-6 p-4 bg-amber-50/80 border border-amber-200/60 rounded-xl text-center shadow-sm">
            <AlertTriangle size={20} className="mx-auto text-amber-500 mb-2" />
            <p className="text-amber-800 font-bold text-sm mb-0.5">لم يتم العثور على المتسابق</p>
            <p className="text-amber-700 text-xs font-semibold">تأكد من صحة الرقم القومي المدخل</p>
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
                className={`block w-full border rounded-xl py-3 pr-11 pl-3 text-sm font-bold outline-none transition-all ${searched && !idValid ? 'border-red-300 bg-red-50 text-red-900' : 'border-outline-variant/30 bg-surface text-on-surface placeholder:text-on-surface-variant/30 hover:border-outline-variant/60 focus:border-primary focus:bg-white focus:shadow-sm focus:ring-2 focus:ring-primary/15'}`} />
              <CreditCard size={16} className={`absolute right-4 top-1/2 -translate-y-1/2 ${searched && !idValid ? 'text-red-400' : 'text-on-surface-variant/30'}`} />
            </div>
            <AnimatePresence>
              {searched && !idValid && <motion.p initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -4 }} className="text-red-500 text-xs font-bold mt-1.5">الرقم القومي يجب أن يتكون من 14 رقماً</motion.p>}
            </AnimatePresence>
          </div>
          <AnimatePresence>
            {error && <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-red-50/80 border border-red-200/60 rounded-xl px-4 py-3 shadow-sm"><p className="text-red-600 text-xs font-bold text-center">{error}</p></motion.div>}
          </AnimatePresence>
          <button type="submit" disabled={loading || !idValid} className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-bold text-sm text-white bg-primary hover:bg-primary/90 active:scale-[0.98] transition-all disabled:opacity-40 disabled:cursor-not-allowed shadow-sm">
            {loading ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : <><Search size={16} /><span>استخراج بطاقة الدعوة</span></>}
          </button>
        </div>
      </form>
      <p className="text-center text-xs text-on-surface-variant/40 mt-6 font-semibold">يرجى إحضار البطاقة المطبوعة أو صورة منها يوم الحفل</p>
    </motion.div>
  );
}
