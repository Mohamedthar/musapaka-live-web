'use client';

import React, { useRef, useState, useEffect } from 'react';
import Link from 'next/link';
import { ArrowLeft, Printer, User, Layers, Calendar, CreditCard, Phone, MapPin, AlertTriangle, BookOpen, List, Download } from 'lucide-react';
import type { CompetitionLevel } from '@/lib/database.types';
import toast from 'react-hot-toast';
import { FlutterIconRow, FlutterGridCell } from '@/components/FlutterIconRow';

interface Step5SuccessProps {
  formData: {
    name: string;
    phone: string;
    nationalId: string;
    birthDate: string;
    gender: string;
    memorizerName: string;
    memorizerPhone: string;
    memorizerAddress: string;
    location: string;
    level: string;
    selectedRewaya: string;
  };
  levels: CompetitionLevel[];
  getLevelContent: () => string;
  examSlot: string;
  profilePreview: string | null;
  birthCertPreview: string | null;
  studentCode: string;
  branchName: string;
  memorizationAmount: number | null;
  onNewSearch?: () => void;
}

export default function Step5Success({
  formData,
  levels,
  getLevelContent,
  examSlot,
  profilePreview,
  birthCertPreview,
  studentCode,
  branchName,
  onNewSearch
}: Step5SuccessProps) {
  const receiptRef = useRef<HTMLDivElement>(null);
  const evalRef = useRef<HTMLDivElement>(null);
  const scaleRef = useRef(1);
  const receiptHeightRef = useRef(0);
  const evalHeightRef = useRef(0);
  const [isDownloading, setIsDownloading] = useState(false);

  const downloadAsImages = async () => {
    setIsDownloading(true);
    const toastId = toast.loading('جاري تجهيز الاستمارات...');
    try {
      const html2canvas = (await import('html2canvas-pro')).default;
      
      const captureElement = async (id: string): Promise<HTMLCanvasElement | null> => {
        const el = document.getElementById(id);
        if (!el) return null;
        
        const canvas = await html2canvas(el, {
          scale: 2,
          useCORS: true,
          backgroundColor: '#ffffff',
          logging: false,
          windowWidth: 850,
          windowHeight: el.scrollHeight + 150,
          onclone: (clonedDoc) => {
            const clonedEl = clonedDoc.getElementById(id);
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
        return canvas;
      };

      const downloadImage = (canvas: HTMLCanvasElement, filename: string): string => {
        const dataUrl = canvas.toDataURL('image/jpeg', 0.85);
        const link = document.createElement('a');
        link.href = dataUrl;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        return dataUrl;
      };

      toast.loading('جاري تجهيز استمارة البيانات...', { id: toastId });
      const receiptCanvas = await captureElement('receipt');
      if (!receiptCanvas) throw new Error('الاستمارة غير موجودة');
      const receiptFilename = `استمارة_بيانات_${formData.name.replace(/\s+/g, '_')}.jpg`;
      const receiptUrl = downloadImage(receiptCanvas, receiptFilename);
      
      let evalUrl: string | null = null;
      let evalFilename = '';
      const evalFormEl = document.getElementById('evaluation-form');
      if (evalFormEl) {
        toast.loading('جاري تجهيز استمارة التقييم...', { id: toastId });
        await new Promise(r => setTimeout(r, 500));
        const evalCanvas = await captureElement('evaluation-form');
        if (evalCanvas) {
          evalFilename = `استمارة_تقييم_${formData.name.replace(/\s+/g, '_')}.jpg`;
          evalUrl = downloadImage(evalCanvas, evalFilename);
        }
      }

      toast.success('تم تحميل الملف', { id: toastId, duration: 4000 });
    } catch (err) {
      console.error(err);
      toast.error('فشل تحميل الصور، يرجى المحاولة مرة أخرى.', { id: toastId });
    } finally {
      setIsDownloading(false);
    }
  };

  useEffect(() => {
    const handleResize = () => {
      const width = window.innerWidth;
      // Target width of our paper sheet container is 800px
      const targetWidth = 800;
      const padding = 32; // 16px on each side
      if (width < targetWidth + padding) {
        scaleRef.current = (width - padding) / targetWidth;
      } else {
        scaleRef.current = 1;
      }
    };

    handleResize();
    window.addEventListener('resize', handleResize);

    // Dynamic ResizeObserver to continuously track dimensions (handles slow-loading fonts, images, etc.)
    const resizeObserver = new ResizeObserver(() => {
      if (receiptRef.current) {
        receiptHeightRef.current = receiptRef.current.scrollHeight;
      }
      if (evalRef.current) {
        evalHeightRef.current = evalRef.current.scrollHeight;
      }
    });

    if (receiptRef.current) {
      resizeObserver.observe(receiptRef.current);
    }
    if (evalRef.current) {
      resizeObserver.observe(evalRef.current);
    }

    return () => {
      window.removeEventListener('resize', handleResize);
      resizeObserver.disconnect();
    };
  }, [formData]);

  const selLevel = levels.find(l => l.title === formData.level);
  const hasTajweed = selLevel?.has_tajweed ?? false;
  const hasRewaya  = selLevel?.has_rewaya  ?? false;
  const hasVoice   = selLevel?.has_voice   ?? false;
  const hasMeaning = selLevel?.has_meaning  ?? false;
  const rewayaScore  = selLevel?.rewaya_max_score  ?? 100;
  const tajweedScore = selLevel?.tajweed_max_score ?? 100;
  const voiceScore   = selLevel?.voice_max_score   ?? 100;
  const meaningScore = selLevel?.meaning_max_score ?? 100;
  const basePoints   = selLevel?.total_points      ?? 100;
  const grandTotal = basePoints
    + (hasRewaya  ? rewayaScore  : 0)
    + (hasTajweed ? tajweedScore : 0)
    + (hasVoice   ? voiceScore   : 0)
    + (hasMeaning ? meaningScore : 0);

  const questions = ['السؤال الأول','السؤال الثاني','السؤال الثالث','السؤال الرابع','السؤال الخامس','السؤال السادس','السؤال السابع','السؤال الثامن','السؤال التاسع','السؤال العاشر'];

  const printCss = '@media print { @page { margin: 0; size: A4 portrait; } header, nav, footer, .print\\\\:hidden, button { display: none !important; } html, body { margin: 0 !important; padding: 0 !important; width: 100% !important; height: auto !important; min-height: 0 !important; background-color: white !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; } #print-wrapper-outer, #print-wrapper-inner { margin: 0 !important; padding: 0 !important; width: 100% !important; max-width: none !important; min-height: 0 !important; height: auto !important; transform: none !important; box-shadow: none !important; background: none !important; display: block !important; } body * { visibility: hidden; } #receipt, #receipt *, #evaluation-form, #evaluation-form * { visibility: visible; } #receipt, #evaluation-form { position: relative !important; margin: 0 auto !important; padding: 0 !important; border: none !important; box-shadow: none !important; border-radius: 0 !important; width: 100% !important; max-width: 100% !important; page-break-inside: avoid; } #receipt { page-break-before: avoid; page-break-after: always; } #evaluation-form { page-break-before: always; } .print-no-scale { transform: none !important; width: 100% !important; height: auto !important; } }';

  return (
    <div id="print-wrapper-outer" className="min-h-screen bg-slate-50/50 print:bg-white py-6 md:py-10 px-4 print:p-0" dir="rtl" style={{ fontFamily: 'Cairo, sans-serif' }}>
      <div id="print-wrapper-inner" className="max-w-[832px] mx-auto print:w-full print:max-w-full">
        
        {/* CSS for print and scaling override */}
        <style dangerouslySetInnerHTML={{ __html: printCss }} />

        {/* ── HEADER ACTIONS BAR ── */}
        <div className="w-full max-w-[800px] mx-auto mb-6 p-2.5 bg-white border border-slate-200/60 rounded-2xl flex flex-col sm:flex-row items-center justify-between gap-3 shadow-sm print:hidden">
          {/* Navigation group */}
          <div className="flex items-center w-full sm:w-auto justify-between sm:justify-start gap-1 border-b border-slate-100 pb-2.5 sm:border-b-0 sm:pb-0">
            <Link 
              href="/" 
              title="الرئيسية"
              className="flex items-center gap-1.5 text-slate-700 hover:text-slate-900 font-bold text-xs sm:text-sm transition-all py-2 px-3 hover:bg-slate-50 rounded-xl active:scale-95"
            >
              <ArrowLeft size={16} className="text-slate-400" />
              <span>الرئيسية</span>
            </Link>
            
            {onNewSearch && (
              <button 
                onClick={onNewSearch} 
                title="استعلام جديد"
                className="flex items-center gap-1.5 text-slate-700 hover:text-slate-900 font-bold text-xs sm:text-sm transition-all py-2 px-3 hover:bg-slate-50 rounded-xl active:scale-95"
              >
                <ArrowLeft size={16} className="text-slate-400 rotate-180" />
                <span>استعلام جديد</span>
              </button>
            )}
          </div>
          
          {/* Action buttons group */}
          <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
            <button 
              onClick={downloadAsImages} 
              disabled={isDownloading}
              title="حفظ كصور"
              className="flex-1 sm:flex-initial flex items-center justify-center gap-1.5 bg-slate-800 hover:bg-slate-900 disabled:bg-slate-500 text-white font-bold text-xs sm:text-sm py-2.5 px-4 rounded-xl shadow-sm hover:shadow active:scale-95 transition-all cursor-pointer whitespace-nowrap"
            >
              <Download size={15} className={isDownloading ? 'animate-spin' : ''} />
              <span>{isDownloading ? 'جاري الحفظ...' : 'حفظ كصور'}</span>
            </button>

            <button 
              onClick={() => window.print()} 
              title="طباعة الاستمارة"
              className="flex-1 sm:flex-initial flex items-center justify-center gap-1.5 bg-slate-900 hover:bg-slate-850 text-white font-bold text-xs sm:text-sm py-2.5 px-4 rounded-xl shadow-sm hover:shadow active:scale-95 transition-all cursor-pointer whitespace-nowrap"
            >
              <Printer size={15} />
              <span>طباعة الاستمارة</span>
            </button>
          </div>
        </div>

        {/* ── RECEIPT ── */}
        <div className="w-full flex justify-center mb-8 print:mb-0">
          <div 
            id="receipt" 
            className="bg-white" 
            style={{ width: '100%', maxWidth: '800px', fontFamily: '"Cairo", sans-serif', direction: 'rtl' }}
          >
            <div ref={receiptRef} style={{ padding: '24pt 24pt 24pt 24pt' }}>
              {/* ── HEADER ──── */}
              {/* ── HEADER ──── */}
              <div style={{ paddingBottom: '8pt', borderBottom: '2pt solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', flexDirection: 'column', flex: 1, paddingLeft: '16pt' }}>
                  <h1 style={{ color: '#0f172a', fontSize: '20pt', fontWeight: 700, margin: 0, lineHeight: 1.2, fontFamily: '"Cairo", sans-serif' }}>مسابقة أهل القرآن الكبرى</h1>
                  <p style={{ color: '#b45309', fontSize: '13pt', fontWeight: 700, margin: '4pt 0 0 0', lineHeight: 1.2, fontFamily: '"Cairo", sans-serif' }}>مقر اللجنة: مركز فاقوس - قرية الديدامون - شارع الشيخ - منزل المشرف العام</p>
                </div>
                <div style={{ width: '70pt', height: '70pt', borderRadius: '50%', overflow: 'hidden', flexShrink: 0 }}>
                  <img src="/logo_musapaka.jpeg" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
              </div>

              {/* ───── BODY ───── */}
              <div style={{ paddingTop: '16pt' }}>

                {/* ── INFO CARD ── */}
                <div style={{ border: '1pt solid #e2e8f0', borderRadius: '10pt', padding: '10pt 12pt', backgroundColor: 'white', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflowWrap: 'break-word' }}>
                    <div style={{ marginBottom: '8pt' }}><FlutterIconRow label="الاسم" value={formData.name} icon={<User size="12pt" color="white" />} /></div>
                    <div style={{ marginBottom: '8pt' }}><FlutterIconRow label="المستوى" value={`${formData.level} - ${getLevelContent()}${formData.selectedRewaya ? ' - ' + formData.selectedRewaya : ''}${branchName ? ' - ' + branchName : ''}`} icon={<Layers size="12pt" color="white" />} /></div>
                    <div style={{ marginBottom: '8pt' }}><FlutterIconRow label="موعد الامتحان" value={examSlot || 'لم يتم التحديد'} icon={<Calendar size="12pt" color="white" />} valueColor="#1e40af" /></div>
                    <FlutterIconRow label="العمر" value={formData.birthDate ? `${(() => { const [y, m, d] = formData.birthDate.split('-').map(Number); const bd = new Date(y, m - 1, d); const now = new Date(); let age = now.getFullYear() - bd.getFullYear(); if (now.getMonth() < bd.getMonth() || (now.getMonth() === bd.getMonth() && now.getDate() < bd.getDate())) age--; return age; })()} سنة` : ''} icon={<User size="12pt" color="white" />} />
                  </div>

                  <div style={{ width: '100pt', minWidth: '100pt', marginRight: '20pt', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <div style={{ width: '100pt', height: '100pt', borderRadius: '50%', border: '2pt solid #f59e0b', overflow: 'hidden', backgroundColor: '#f8fafc', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {profilePreview ? (
                        <img src={profilePreview} alt="Profile" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      ) : (
                        <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f1f5f9' }}>
                          <User size={48} color="#94a3b8" />
                        </div>
                      )}
                    </div>
                    <div style={{ marginTop: '10pt', padding: '4pt 12pt', backgroundColor: '#eeeeee', borderRadius: '16pt', display: 'flex', alignItems: 'center' }}>
                      <span style={{ fontSize: '12pt', fontWeight: 700, color: '#0f172a', fontFamily: "'Cairo', sans-serif" }}>{studentCode || formData.nationalId}</span>
                      <span style={{ marginRight: '4pt', display: 'flex' }}><User size="10pt" color="#0f172a" /></span>
                    </div>
                  </div>
                </div>

                <div style={{ height: '24pt' }} />

                {/* ── BIRTH CERTIFICATE ── */}
                {birthCertPreview && (
                  <div style={{ border: '1pt solid #e2e8f0', borderRadius: '10pt', padding: '10pt 12pt', backgroundColor: 'white', textAlign: 'center' }}>
                    <p style={{ fontSize: '12pt', fontWeight: 700, color: '#0f172a', margin: '0 0 8pt 0', fontFamily: '"Cairo", sans-serif' }}>صورة شهادة الميلاد</p>
                    <img src={birthCertPreview} alt="شهادة الميلاد" style={{ maxWidth: '100%', maxHeight: '300pt', borderRadius: '6pt', objectFit: 'contain' }} />
                  </div>
                )}

                <div style={{ height: '24pt' }} />

                {/* ── DETAILED DATA GRID ── */}
                <div style={{ position: 'relative' }}>
                  <div style={{ 
                    border: '1pt solid #e2e8f0', 
                    borderRadius: '12pt', 
                    backgroundColor: 'white',
                    overflow: 'visible',
                  }}>
                    {/* Badge - centered, overlapping top border like Flutter */}
                    <div style={{ display: 'flex', justifyContent: 'center' }}>
                      <div style={{ 
                        backgroundColor: '#0f172a', padding: '3pt 12pt', borderRadius: '8pt', 
                        display: 'inline-flex', alignItems: 'center',
                        marginTop: '-12pt',
                      }}>
                        <div style={{ padding: '2pt', backgroundColor: '#0f172a', borderRadius: '4pt', display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 0 }}>
                          <List size="12pt" color="white" />
                        </div>
                        <span style={{ marginRight: '6pt', fontSize: '12pt', fontWeight: 700, color: 'white', fontFamily: '"Cairo", sans-serif' }}>البيانات التفصيلية</span>
                      </div>
                    </div>
                    {/* Grid content */}
                    <div style={{ 
                      display: 'grid',
                      gridTemplateColumns: '1fr 1fr',
                      backgroundColor: '#e2e8f0',
                      gap: '1px',
                      marginTop: '2pt',
                    }}>
                    <FlutterGridCell label="الرقم القومي" value={formData.nationalId} icon={<CreditCard size="10pt" color="white" />} isTopRow={true} bg="#f8fafc" />
                    <FlutterGridCell label="هاتف الطالب / ولي الأمر" value={formData.phone} icon={<Phone size="10pt" color="white" />} isTopRow={true} bg="#f8fafc" />
                    
                    <FlutterGridCell label="تاريخ الميلاد" value={formData.birthDate} icon={<Calendar size="10pt" color="white" />} />
                    <FlutterGridCell label="النوع" value={formData.gender} icon={<User size="10pt" color="white" />} />
                    
                    <FlutterGridCell label="المحفظ" value={formData.memorizerName || '-'} icon={<User size="10pt" color="white" />} bg="#f8fafc" />
                    <FlutterGridCell label="هاتف المحفظ" value={formData.memorizerPhone || '-'} icon={<BookOpen size="10pt" color="white" />} bg="#f8fafc" />
                    
                    <FlutterGridCell label="عنوان الطالب" value={formData.location || '-'} icon={<MapPin size="10pt" color="white" />} />
                    <FlutterGridCell label="عنوان المحفظ" value={formData.memorizerAddress || '-'} icon={<MapPin size="10pt" color="white" />} />
                  </div>
                  </div>
                </div>

                <div style={{ height: '24pt' }} />

                {/* ── NOTES / CONDITIONS ── */}
                <div style={{ border: '1pt solid #e2e8f0', borderRadius: '10pt', backgroundColor: '#f8fafc' }}>
                  {/* Badge - inside container, overlapping top border like Flutter */}
                  <div style={{ display: 'flex', justifyContent: 'center' }}>
                    <div style={{ 
                      backgroundColor: '#0f172a', padding: '3pt 12pt', borderRadius: '8pt',
                      display: 'inline-flex', alignItems: 'center',
                      marginTop: '-12pt',
                    }}>
                      <div style={{ padding: '2pt', backgroundColor: '#0f172a', borderRadius: '4pt', display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 0 }}>
                        <List size="12pt" color="white" />
                      </div>
                      <span style={{ marginRight: '5pt', fontSize: '14pt', fontWeight: 700, color: 'white', fontFamily: '"Cairo", sans-serif' }}>ملاحظات هامة</span>
                    </div>
                  </div>
                  {/* Content */}
                  <div style={{ padding: '2pt 12pt 8pt 12pt' }}>
                    {[
                      'القبول بشروط المسابقة، يحظر تقديم أي رسوم مالية',
                      'كل متسابق يلتزم بالمواعيد المحدده له( التقديم - الاختبار - الحفلة)',
                      'يتم التصفيه في المسابقة بوضع سؤال للتصفية في الامتحان سؤال في ضبط المتشابهات',
                      'سيتم تكريم الاوائل الثلاثة على المنصة فقط والباقي في أماكنهم والرجاء الرضا بذلك',
                      'عند عدم الحضور المكرم الحفل يحجب من الجائزة وتودع في الامانات',
                      'سيتم تكريم الحاصلين علي درجة نجاح 95% فأكثر، ويحظر الجمع بين أكثر من جائزة',
                    ].map((text, i) => (
                      <div key={i} style={{ display: 'flex', alignItems: 'flex-start', paddingBottom: '6pt' }}>
                        <div style={{ width: '20pt', height: '20pt', minWidth: '20pt', borderRadius: '50%', backgroundColor: '#0f172a', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                          <span style={{ fontSize: '11pt', fontWeight: 700, color: 'white', fontFamily: '"Cairo", sans-serif' }}>{i + 1}</span>
                        </div>
                        <span style={{ marginRight: '6pt', fontSize: '13pt', fontWeight: 400, color: '#0f172a', lineHeight: 1.4, textAlign: 'right', flex: 1, fontFamily: '"Cairo", sans-serif' }}>{text}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div style={{ height: '14pt' }} />

                {/* ── SUPERVISOR + WARNING + QR CODE ── */}
                <div style={{ display: 'flex', alignItems: 'flex-start' }}>
                  {/* Left side: Supervisor + Warning */}
                  <div style={{ flex: 1 }}>
                    <div style={{ textAlign: 'center' }}>
                      <p style={{ color: '#b45309', fontSize: '12pt', fontWeight: 700, margin: 0, fontFamily: '"Cairo", sans-serif' }}>{'المشرف العام علي المسابقة'}</p>
                      <p style={{ color: '#0f172a', fontSize: '18pt', fontWeight: 700, marginTop: 2, fontFamily: '"Cairo", sans-serif' }}>{'أ/ مصطفى عبدالرحمن محمد سالم'}</p>
                    </div>
                    <div style={{ height: '8pt' }} />
                    {/* Warning Box */}
                    <div style={{ padding: '6pt 10pt', border: '1.5pt solid #f59e0b', borderRadius: '8pt', backgroundColor: '#fffbeb', display: 'flex', alignItems: 'flex-start' }}>
                      <AlertTriangle size="14pt" color="#b45309" style={{ flexShrink: 0, marginLeft: '6pt' }} />
                      <span style={{ fontSize: '10pt', fontWeight: 700, color: '#92400e', fontFamily: '"Cairo", sans-serif', lineHeight: 1.4 }}>يجب طباعة هذه الاستمارة في ورقة واحدة وإحضارها معك في موعد الاختبار المحدد لك أعلاه.</span>
                    </div>
                  </div>
                  {/* Right side: QR Code */}
                  <div style={{ width: '12pt', flexShrink: 0 }} />
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0 }}>
                    <div style={{ width: '70pt', height: '70pt' }}>
                      <img 
                        src="https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=https://maps.app.goo.gl/F75xUpSbdsfzDmHn8" 
                        alt="رمز QR لتوجيهك إلى موقع اللجنة على خرائط جوجل" 
                        style={{ width: '100%', height: '100%', objectFit: 'contain' }} 
                      />
                    </div>
                    <p style={{ color: '#0f172a', fontSize: '9pt', fontWeight: 700, margin: '3pt 0 0 0', textAlign: 'center', fontFamily: '"Cairo", sans-serif', lineHeight: 1.3 }}>
                      امسح الباركود<br/>لمعرفة مقر اللجنة
                    </p>
                  </div>
                </div>

              </div>
            </div>
          </div>
        </div>

        {/* ── EVALUATION FORM — الصفحة الثانية (Scaled Down on Screen to Fit viewport) ── */}
            <div className="w-full flex justify-center mb-8 print:mb-0">
              <div 
                id="evaluation-form" 
                className="bg-white" 
                style={{ width: '100%', maxWidth: '800px', fontFamily: '"Cairo", sans-serif', direction: 'rtl', pageBreakBefore: 'always' }}
              >
                <div ref={evalRef} style={{ padding: '20pt 24pt 24pt 24pt' }}>

                  {/* Header */}
                  <div style={{ paddingBottom: '12pt', borderBottom: '2pt solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', flex: 1, paddingLeft: '16pt' }}>
                      <h2 style={{ color: '#0f172a', fontSize: '22pt', fontWeight: 700, margin: 0, lineHeight: 1.2, fontFamily: '"Cairo", sans-serif' }}>مسابقة أهل القرآن الكبرى</h2>
                      <p style={{ color: '#b45309', fontSize: '14pt', fontWeight: 700, margin: '4pt 0 0 0', lineHeight: 1, fontFamily: '"Cairo", sans-serif' }}>استمارة تقييم المتسابق</p>
                    </div>
                    <div style={{ width: '70pt', height: '70pt', borderRadius: '50%', overflow: 'hidden', flexShrink: 0 }}>
                      <img src="/logo_musapaka.jpeg" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    </div>
                  </div>

                  <div style={{ paddingTop: '16pt' }}>

                    {/* Student Mini Info */}
                    <div style={{ border: '1pt solid #e2e8f0', borderRadius: '8pt', padding: '12pt 16pt', backgroundColor: '#f8fafc', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24pt' }}>
                      <span style={{ fontSize: '13pt', fontWeight: 700, color: '#0f172a', fontFamily: '"Cairo", sans-serif' }}>
                        الاسم: {formData.name}
                      </span>
                      <span style={{ fontSize: '13pt', fontWeight: 700, color: '#0f172a', fontFamily: '"Cairo", sans-serif', textAlign: 'left', flex: 1, marginRight: '16pt' }}>
                        {formData.level}{selLevel?.content ? ` - ${selLevel.content}` : ''}
                        {formData.selectedRewaya ? ` - ${formData.selectedRewaya}` : ''}
                        {branchName && (
                          <span style={{ color: '#dc2626' }}>{` (${branchName})`}</span>
                        )}
                      </span>
                    </div>

                    {/* Score Table */}
                    <div style={{ border: '1.5pt solid #0f172a', borderRadius: '8pt', overflow: 'hidden' }}>
                      <table style={{ width: '100%', borderCollapse: 'collapse', direction: 'rtl' }}>
                        <thead>
                          <tr style={{ backgroundColor: '#0f172a' }}>
                            <th style={{ width: '30%', padding: '8pt 10pt', textAlign: 'center', color: 'white', fontSize: '14pt', fontWeight: 700, fontFamily: '"Cairo", sans-serif', borderLeft: '1pt solid #0f172a' }}>السؤال</th>
                            <th style={{ width: '45%', padding: '8pt 10pt', textAlign: 'center', color: 'white', fontSize: '14pt', fontWeight: 700, fontFamily: '"Cairo", sans-serif', borderLeft: '1pt solid #0f172a' }}>ملاحظات</th>
                            <th style={{ width: '25%', padding: '8pt 10pt', textAlign: 'center', color: 'white', fontSize: '14pt', fontWeight: 700, fontFamily: '"Cairo", sans-serif' }}>الدرجة</th>
                          </tr>
                        </thead>
                        <tbody>
                          {questions.map((q, i) => (
                            <tr key={i} style={{ backgroundColor: i % 2 !== 0 ? '#f8fafc' : 'white', borderTop: '1pt solid #cbd5e1' }}>
                              <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '13pt', color: '#0f172a', fontFamily: '"Cairo", sans-serif', whiteSpace: 'nowrap', borderLeft: '1pt solid #cbd5e1' }}>{q}</td>
                              <td style={{ padding: '8pt 10pt', borderLeft: '1pt solid #cbd5e1', minWidth: '120pt' }}></td>
                              <td style={{ padding: '8pt 10pt 8pt 20pt', textAlign: 'left', fontWeight: 700, fontSize: '15pt', color: '#0f172a', fontFamily: 'monospace', paddingLeft: '20pt' }}>/ 10</td>
                            </tr>
                          ))}
                          {/* Questions subtotal */}
                          <tr style={{ backgroundColor: '#f1f5f9' }}>
                            <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '13pt', color: '#0f172a', fontFamily: '"Cairo", sans-serif', whiteSpace: 'nowrap', borderLeft: '1pt solid #cbd5e1', borderTop: '2pt solid #0f172a' }}>المجموع</td>
                            <td style={{ borderLeft: '1pt solid #cbd5e1', borderTop: '2pt solid #0f172a' }}></td>
                            <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '15pt', color: '#0f172a', fontFamily: 'monospace', paddingLeft: '20pt', borderTop: '2pt solid #0f172a' }}>/ 100</td>
                          </tr>
                          {/* Rewaya */}
                          {hasRewaya && (
                            <tr style={{ backgroundColor: 'white', borderTop: '1pt solid #cbd5e1' }}>
                              <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '13pt', color: '#0f172a', fontFamily: '"Cairo", sans-serif', borderLeft: '1pt solid #cbd5e1' }}>
                                الرواية{formData.selectedRewaya ? ` (${formData.selectedRewaya})` : ''}
                              </td>
                              <td style={{ borderLeft: '1pt solid #cbd5e1' }}></td>
                              <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '15pt', color: '#0f172a', fontFamily: 'monospace', paddingLeft: '24pt' }}>/ {rewayaScore}</td>
                            </tr>
                          )}
                          {/* Tajweed */}
                          {hasTajweed && (
                            <tr style={{ backgroundColor: '#f8fafc', borderTop: '1pt solid #cbd5e1' }}>
                              <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '13pt', color: '#0f172a', fontFamily: '"Cairo", sans-serif', borderLeft: '1pt solid #cbd5e1' }}>التجويد</td>
                              <td style={{ borderLeft: '1pt solid #cbd5e1' }}></td>
                              <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '15pt', color: '#0f172a', fontFamily: 'monospace', paddingLeft: '24pt' }}>/ {tajweedScore}</td>
                            </tr>
                          )}
                          {/* Voice */}
                          {hasVoice && (
                            <tr style={{ backgroundColor: 'white', borderTop: '1pt solid #cbd5e1' }}>
                              <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '13pt', color: '#0f172a', fontFamily: '"Cairo", sans-serif', borderLeft: '1pt solid #cbd5e1' }}>حسن الصوت</td>
                              <td style={{ borderLeft: '1pt solid #cbd5e1' }}></td>
                              <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '15pt', color: '#0f172a', fontFamily: 'monospace', paddingLeft: '24pt' }}>/ {voiceScore}</td>
                            </tr>
                          )}
                          {/* Meaning */}
                          {hasMeaning && (
                            <tr style={{ backgroundColor: '#f8fafc', borderTop: '1pt solid #cbd5e1' }}>
                              <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '13pt', color: '#0f172a', fontFamily: '"Cairo", sans-serif', borderLeft: '1pt solid #cbd5e1' }}>فهم المعاني</td>
                              <td style={{ borderLeft: '1pt solid #cbd5e1' }}></td>
                              <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '15pt', color: '#0f172a', fontFamily: 'monospace', paddingLeft: '24pt' }}>/ {meaningScore}</td>
                            </tr>
                          )}
                          {/* Grand Total */}
                          <tr style={{ backgroundColor: '#fef3c7' }}>
                            <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '14pt', color: '#0f172a', fontFamily: '"Cairo", sans-serif', borderLeft: '1pt solid #cbd5e1' }}>المجموع الكلي للقسم</td>
                            <td style={{ borderLeft: '1pt solid #cbd5e1' }}></td>
                            <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '16pt', color: '#0f172a', fontFamily: 'monospace', paddingLeft: '24pt' }}>/ {grandTotal}</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                    <div style={{ height: '24pt' }} />
                  </div>
                </div>
              </div>
            </div>

      </div>
    </div>
  );
}

