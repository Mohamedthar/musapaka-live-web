'use client';

import React, { useState, useRef, useEffect } from 'react';
import { CreditCard, Search, CalendarCheck, Info, User, Layers, Printer, Download, MapPin, Hash } from 'lucide-react';
import Image from 'next/image';
import toast from 'react-hot-toast';

interface CeremonyData {
  name: string;
  gender: 'M' | 'F';
  level: string;
  level_content: string;
  ceremony_code: string;
  profile_image_url: string | null;
  is_eligible: boolean;
}

export default function CeremonyInquiry() {
  const [nationalId, setNationalId] = useState('');
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [data, setData] = useState<CeremonyData | null>(null);
  
  const receiptRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);
  const [receiptHeight, setReceiptHeight] = useState(0);
  const [isDownloading, setIsDownloading] = useState(false);

  const handleInquiry = async (e: React.FormEvent) => {
    e.preventDefault();
    if (nationalId.length !== 14) {
      setError('الرقم القومي يجب أن يتكون من 14 رقماً');
      return;
    }

    setError('');
    setLoading(true);
    setSearched(true);
    setData(null);

    try {
      const response = await fetch('/api/ceremony', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ nationalId }),
      });

      const resData = await response.json();

      if (!response.ok) {
        setError(resData.error || 'حدث خطأ أثناء الاستعلام');
        return;
      }

      setData(resData.student);
    } catch (err) {
      console.error('Fetch error:', err);
      setError('فشل الاتصال بالخادم. يرجى المحاولة مرة أخرى.');
    } finally {
      setLoading(false);
    }
  };

  const handleNewSearch = () => {
    setData(null);
    setSearched(false);
    setError('');
    setNationalId('');
  };

  const downloadAsImage = async () => {
    setIsDownloading(true);
    const toastId = toast.loading('جاري تجهيز بطاقة الدعوة وتحميلها كصورة...');
    try {
      const html2canvas = (await import('html2canvas-pro')).default;
      const el = document.getElementById('ceremony-ticket');
      if (!el) return;
      
      const canvas = await html2canvas(el, {
        scale: 2,
        useCORS: true,
        backgroundColor: '#ffffff',
        logging: false,
        windowWidth: 850,
        windowHeight: el.scrollHeight + 150,
        onclone: (clonedDoc) => {
          const clonedEl = clonedDoc.getElementById('ceremony-ticket');
          if (clonedEl) {
            clonedEl.style.transform = 'none';
            clonedEl.style.transformOrigin = 'top center';
            clonedEl.style.width = '800px';
            clonedEl.style.height = 'auto';
            
            const clonedParent = clonedEl.parentElement;
            if (clonedParent) {
              clonedParent.style.height = 'auto';
              clonedParent.style.overflow = 'visible';
              clonedParent.style.transform = 'none';
            }
          }
        }
      });
      
      const dataUrl = canvas.toDataURL('image/png');
      const link = document.createElement('a');
      link.href = dataUrl;
      link.download = `دعوة_حفل_${data?.name?.replace(/\s+/g, '_')}.png`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      toast.success('تم تحميل بطاقة الدعوة كصورة بنجاح!', { id: toastId });
    } catch (err) {
      console.error(err);
      toast.error('فشل تحميل الصورة، يرجى المحاولة مرة أخرى.', { id: toastId });
    } finally {
      setIsDownloading(false);
    }
  };

  useEffect(() => {
    if (!data || !data.is_eligible) return;

    const handleResize = () => {
      const width = window.innerWidth;
      const targetWidth = 800;
      const padding = 32; 
      if (width < targetWidth + padding) {
        setScale((width - padding) / targetWidth);
      } else {
        setScale(1);
      }
    };

    handleResize();
    window.addEventListener('resize', handleResize);

    const resizeObserver = new ResizeObserver(() => {
      if (receiptRef.current) {
        setReceiptHeight(receiptRef.current.scrollHeight);
      }
    });

    if (receiptRef.current) {
      resizeObserver.observe(receiptRef.current);
    }

    return () => {
      window.removeEventListener('resize', handleResize);
      resizeObserver.disconnect();
    };
  }, [data]);

  if (data) {
    if (!data.is_eligible) {
      return (
        <div className="bg-[var(--bg-section)] border border-[var(--border)] rounded-3xl p-8 sm:p-10 text-center animate-fade-in">
          <div className="w-16 h-16 bg-white border border-[var(--border)] text-slate-400 rounded-full flex items-center justify-center mx-auto mb-4 shadow-sm">
            <Info size={32} />
          </div>
          <h2 className="text-xl font-black text-[var(--text-primary)] mb-2">عذراً، غير مؤهل للحضور</h2>
          <p className="text-slate-500 text-sm max-w-sm mx-auto font-semibold mb-8 leading-relaxed">
            عزيزي المتسابق، حضور الحفل الختامي مقتصر على الطلاب الحاصلين على تقدير امتياز (95% فأكثر). نسأل الله لك التوفيق والنجاح في المرات القادمة.
          </p>
          <button
            onClick={handleNewSearch}
            className="px-6 py-2.5 rounded-xl font-bold bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white transition-colors text-sm shadow-sm"
          >
            استعلام عن متسابق آخر
          </button>
        </div>
      );
    }

    return (
      <div className="w-full mx-auto" dir="rtl" style={{ fontFamily: 'Cairo, sans-serif' }}>
        <style dangerouslySetInnerHTML={{ __html: `
          @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700;900&display=swap');
          @media print {
            @page { margin: 0; }
            .print-no-scale {
              transform: none !important;
              width: 100% !important;
              height: auto !important;
            }
            body * {
              visibility: hidden;
            }
            #ceremony-ticket-container, #ceremony-ticket-container * {
              visibility: visible;
            }
            #ceremony-ticket-container {
              position: absolute;
              left: 0;
              top: 0;
              width: 100%;
            }
          }
        ` }} />

        {/* ── HEADER ACTIONS BAR ── */}
        <div className="w-full max-w-[800px] mx-auto mb-6 p-2.5 bg-white border border-[var(--border)] rounded-2xl flex flex-col sm:flex-row items-center justify-between gap-3 shadow-sm print:hidden">
          <div className="flex items-center w-full sm:w-auto justify-between sm:justify-start gap-1">
            <button 
              onClick={handleNewSearch} 
              title="استعلام جديد"
              className="flex items-center gap-1.5 text-slate-700 hover:text-slate-900 font-bold text-xs sm:text-sm transition-all py-2 px-3 hover:bg-slate-50 rounded-xl active:scale-95"
            >
              <Search size={16} className="text-slate-400" />
              <span>استعلام جديد</span>
            </button>
          </div>
          
          <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
            <button 
              onClick={downloadAsImage} 
              disabled={isDownloading}
              title="حفظ كصورة"
              className="flex-1 sm:flex-initial flex items-center justify-center gap-1.5 bg-[var(--primary)] hover:bg-[var(--primary-hover)] disabled:bg-slate-400 text-white font-bold text-xs sm:text-sm py-2.5 px-4 rounded-xl shadow-sm hover:shadow active:scale-95 transition-all cursor-pointer whitespace-nowrap"
            >
              <Download size={15} className={isDownloading ? 'animate-spin' : ''} />
              <span>{isDownloading ? 'جاري الحفظ...' : 'حفظ كصورة'}</span>
            </button>

            <button 
              onClick={() => window.print()} 
              title="طباعة البطاقة"
              className="flex-1 sm:flex-initial flex items-center justify-center gap-1.5 bg-[var(--bg-section)] hover:bg-[var(--bg-section)] text-[var(--text-primary)] border border-[var(--border)] font-bold text-xs sm:text-sm py-2.5 px-4 rounded-xl shadow-sm hover:shadow active:scale-95 transition-all cursor-pointer whitespace-nowrap"
            >
              <Printer size={15} />
              <span>طباعة الدعوة</span>
            </button>
          </div>
        </div>

        {/* ── RECEIPT ── */}
        <div 
          id="ceremony-ticket-container"
          className="w-full flex justify-center overflow-hidden print:block print:w-full print:h-auto print:overflow-visible mb-8 print:mb-0" 
          style={{ height: scale < 1 ? `${(receiptHeight + 16) * scale}px` : 'auto' }}
        >
          <div 
            id="ceremony-ticket" 
            className="print-no-scale bg-white border border-[var(--border)] shadow-md rounded-3xl print:border-none print:rounded-none print:shadow-none flex-shrink-0" 
            style={{ 
              transform: scale < 1 ? `scale(${scale})` : 'none', 
              transformOrigin: 'top center',
              width: '800px',
              fontFamily: '"Cairo", sans-serif', 
              direction: 'rtl' 
            }}
          >
            <div ref={receiptRef} style={{ padding: '36pt 24pt 36pt 24pt' }}>
              {/* ── HEADER ───── */}
              <div style={{ paddingBottom: '12pt', borderBottom: '2pt solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', flexDirection: 'column', flex: 1, paddingLeft: '16pt' }}>
                  <h1 style={{ color: 'var(--text-primary)', fontSize: '20pt', fontWeight: 900, margin: 0, lineHeight: 1.2, fontFamily: '"Cairo", sans-serif' }}>مسابقة أهل القرآن الكبرى</h1>
                  <p style={{ color: 'var(--text-primary)', fontSize: '14pt', fontWeight: 700, margin: '4pt 0 0 0', lineHeight: 1, fontFamily: '"Cairo", sans-serif' }}>دعوة حضور الحفل الختامي</p>
                </div>
                <div style={{ width: '70pt', height: '70pt', borderRadius: '50%', overflow: 'hidden', flexShrink: 0 }}>
                  <img src="/logo_musapaka.jpeg" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
              </div>

              {/* ───── BODY ───── */}
              <div style={{ paddingTop: '16pt' }}>

                {/* ── INFO CARD ── */}
                <div style={{ border: '1px solid var(--border)', borderRadius: '12pt', padding: '12pt', backgroundColor: 'var(--bg-section)', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                    <div style={{ marginBottom: '8pt' }}><FlutterIconRow label="الاسم" value={data.name} icon={<User size="12pt" color="white" />} /></div>
                    <div style={{ marginBottom: '8pt' }}><FlutterIconRow label="المستوى" value={data.level} icon={<Layers size="12pt" color="white" />} /></div>
                    <div style={{ marginBottom: '8pt' }}><FlutterIconRow label="المحتوى" value={data.level_content} icon={<Info size="12pt" color="white" />} /></div>
                    
                    <div style={{ height: '8pt' }} />
                    <FlutterIconRow label="كود الحضور" value={data.ceremony_code} icon={<Hash size="12pt" color="white" />} valueColor="var(--text-primary)" />
                  </div>

                  <div style={{ width: '90pt', minWidth: '90pt', marginRight: '20pt', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <div style={{ width: '90pt', height: '90pt', borderRadius: '50%', border: '2.5pt solid var(--primary)', overflow: 'hidden', backgroundColor: '#f8fafc', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {data.profile_image_url ? (
                        <img src={data.profile_image_url} alt="Profile" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      ) : (
                        <User size="45pt" color="#94a3b8" />
                      )}
                    </div>
                  </div>
                </div>

                <div style={{ height: '24pt' }} />

                {/* ── NOTES / CONGRATULATIONS ── */}
                <div style={{ position: 'relative', marginTop: '10pt' }}>
                  <div style={{ border: '1px solid var(--border)', borderRadius: '12pt', padding: '20pt 16pt 16pt 16pt', backgroundColor: 'white' }}>
                    <p style={{ fontSize: '13pt', fontWeight: 700, color: 'var(--text-primary)', lineHeight: 1.6, fontFamily: '"Cairo", sans-serif', margin: 0, textAlign: 'center' }}>
                      تهانينا القلبية لك! لقد اجتزت اختبارات المسابقة بتفوق. يسعدنا ويشرفنا حضورك حفل التكريم الختامي لتكريمك وتتويجك، سائلين المولى عز وجل أن يجعلك من أهل القرآن.
                    </p>
                  </div>
                  {/* Badge Overlay */}
                  <div style={{ position: 'absolute', top: 0, left: '50%', transform: 'translate(-50%, -50%)', backgroundColor: 'var(--bg-section)', padding: '4pt 12pt', borderRadius: '16pt', border: '1.5pt solid var(--border)', display: 'flex', alignItems: 'center' }}>
                    <div style={{ padding: '3pt', backgroundColor: 'var(--primary)', borderRadius: '4pt', display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 0 }}>
                      <CalendarCheck size="10pt" color="white" />
                    </div>
                    <span style={{ marginRight: '6pt' }} />
                    <span style={{ fontSize: '12pt', fontWeight: 900, color: 'var(--text-primary)', fontFamily: "'Cairo', sans-serif" }}>دعوة تكريم</span>
                  </div>
                </div>

                <div style={{ height: '36pt' }} />

                {/* ── SUPERVISOR ── */}
                <div style={{ textAlign: 'center' }}>
                  <p style={{ color: 'var(--beige-dark)', fontSize: '11pt', fontWeight: 900, margin: 0, fontFamily: "'Cairo', sans-serif" }}>المشرف العام علي المسابقة</p>
                  <p style={{ color: 'var(--text-primary)', fontSize: '16pt', fontWeight: 900, margin: '2pt 0 0 0', fontFamily: "'Cairo', sans-serif" }}>أ/ مصطفى عبدالرحمن محمد سالم</p>
                  <p style={{ color: '#64748b', fontSize: '11pt', fontWeight: 600, margin: '6pt 0 0 0', fontFamily: '"Cairo", sans-serif' }}>مقر اللجنة: مركز فاقوس - قرية الديدمون - شارع الشيخ - منزل المشرف العام</p>
                </div>

                <div style={{ height: '24pt' }} />

                {/* ── FOOTER WARNING ── */}
                <div style={{ padding: '10pt 16pt', border: '1.5pt solid var(--border)', borderRadius: '10pt', backgroundColor: 'var(--bg-section)', display: 'flex', alignItems: 'center' }}>
                  <span style={{ color: 'var(--text-primary)', display: 'flex', marginLeft: '10pt' }}><Info size="18pt" /></span>
                  <span style={{ fontSize: '11pt', fontWeight: 900, color: 'var(--text-primary)', marginLeft: '6pt', fontFamily: '"Cairo", sans-serif' }}>تعليمات الدخول:</span>
                  <span style={{ fontSize: '10pt', fontWeight: 700, color: 'var(--text-primary)', flex: 1, fontFamily: '"Cairo", sans-serif' }}>يرجى طباعة هذه الاستمارة أو الاحتفاظ بها على هاتفك لإبرازها للمنظمين يوم الحفل.</span>
                </div>

              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full animate-fade-in">
      <div className="text-center mb-8">
        <div className="inline-flex items-center justify-center w-12 h-12 bg-[var(--bg-section)] text-[var(--text-primary)] rounded-2xl mb-4 border border-[var(--border)] shadow-sm">
          <CalendarCheck size={24} />
        </div>
        <h2 className="text-xl font-black text-[var(--text-primary)] mb-2">استعلام حضور الحفل الختامي</h2>
        <p className="text-slate-500 text-xs sm:text-sm font-semibold max-w-sm mx-auto leading-relaxed">
          أدخل الرقم القومي لمعرفة موقفك من حضور حفل التكريم واستخراج بطاقة الدعوة الخاصة بك.
        </p>
      </div>

      <form onSubmit={handleInquiry} className="space-y-5 max-w-md mx-auto">
        <div className="space-y-1.5 relative">
          <label className="block text-sm font-bold text-[var(--text-primary)]">الرقم القومي للمتسابق <span className="text-red-500">*</span></label>
          <div className="relative group">
            <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-[var(--primary)] transition-colors">
              <CreditCard size={17} />
            </span>
            <input
              type="number"
              value={nationalId}
              onChange={e => { setNationalId(e.target.value); setError(''); setSearched(false); }}
              placeholder="أدخل الـ 14 رقماً للمتسابق"
              className={`w-full bg-[var(--bg-section)] border ${searched && nationalId.length !== 14 ? 'border-red-300 focus:border-red-500 focus:ring-red-200' : 'border-[var(--border)] focus:border-[var(--primary)] focus:ring-[var(--primary-glow)]'} rounded-xl px-10 py-3.5 text-sm font-semibold outline-none transition-all focus:bg-white focus:ring-4 text-[var(--text-primary)]`}
              required
            />
          </div>
          {searched && nationalId.length !== 14 && <p className="text-red-500 text-xs font-bold mt-1">الرقم القومي يجب أن يتكون من 14 رقماً</p>}
        </div>

        {error && <p className="text-red-500 text-xs font-bold text-center mt-2">{error}</p>}

        <button
          type="submit"
          disabled={loading || nationalId.length !== 14}
          className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-bold bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed mt-2"
        >
          {loading ? (
            <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <>
              <span>استخراج بطاقة الدعوة</span>
              <Search size={16} />
            </>
          )}
        </button>
      </form>
    </div>
  );
}

// Helper specific to Flutter-style Receipt Layout
function FlutterIconRow({ label, value, icon, valueColor = 'var(--text-primary)' }: { label: string; value: string; icon: React.ReactNode; valueColor?: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', fontFamily: '"Cairo", sans-serif' }}>
      <div style={{ padding: '5pt', backgroundColor: 'var(--primary)', borderRadius: '6pt', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, lineHeight: 0 }}>
        {icon}
      </div>
      <span style={{ marginRight: '8pt', fontSize: '12pt', fontWeight: 400, color: 'var(--text-primary)', whiteSpace: 'nowrap', fontFamily: '"Cairo", sans-serif' }}>{label}</span>
      <span style={{ marginRight: '4pt', fontSize: '12pt', fontWeight: 400, color: 'var(--text-primary)', fontFamily: '"Cairo", sans-serif' }}>:</span>
      <span style={{ marginRight: '8pt', fontSize: '13pt', fontWeight: 700, color: valueColor, textAlign: 'right', flex: 1, fontFamily: '"Cairo", sans-serif' }}>{value}</span>
    </div>
  );
}
