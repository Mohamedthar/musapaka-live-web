'use client';

import React, { useRef, useState, useEffect } from 'react';
import Link from 'next/link';
import { ArrowLeft, Search, Printer, User, Layers, Calendar, CreditCard, Phone, MapPin, AlertTriangle, BookOpen, List, Download } from 'lucide-react';
import type { CompetitionLevel } from '@/lib/database.types';
import toast from 'react-hot-toast';
import { FlutterIconRow, FlutterGridCell } from '@/components/FlutterIconRow';
import { parseNationalId } from '@/lib/national-id';

interface Step5SuccessProps {
  formData: {
    name: string;
    phone: string;
    nationalId: string;
    age: string;
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
  studentCode: string;
  isWaitlistMode: boolean;
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
  studentCode,
  isWaitlistMode,
  branchName,
  memorizationAmount,
  onNewSearch
}: Step5SuccessProps) {
  const receiptRef = useRef<HTMLDivElement>(null);
  const evalRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);
  const [receiptHeight, setReceiptHeight] = useState(0);
  const [evalHeight, setEvalHeight] = useState(0);
  const [isDownloading, setIsDownloading] = useState(false);

  const downloadAsImages = async () => {
    setIsDownloading(true);
    const toastId = toast.loading('جاري تجهيز الاستمارات وتحميلها كصور...');
    try {
      const html2canvas = (await import('html2canvas-pro')).default;
      
      const captureElement = async (id: string, filename: string): Promise<boolean> => {
        const el = document.getElementById(id);
        if (!el) {
          toast.error('لم يتم العثور على العنصر', { id: toastId });
          return false;
        }
        
        const canvas = await html2canvas(el, {
          scale: 2, // 2x resolution
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
        
        const dataUrl = canvas.toDataURL('image/png');
        const link = document.createElement('a');
        link.href = dataUrl;
        link.download = `${filename}.png`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        return true;
      };

      const receiptOk = await captureElement('receipt', `استمارة_بيانات_${formData.name.replace(/\s+/g, '_')}`);
      
      const evalFormEl = document.getElementById('evaluation-form');
      if (evalFormEl) {
        await captureElement('evaluation-form', `استمارة_تقييم_${formData.name.replace(/\s+/g, '_')}`);
      }
      
      if (receiptOk) {
        toast.success('تم تحميل الاستمارات كصور بنجاح!', { id: toastId });
      }
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
        setScale((width - padding) / targetWidth);
      } else {
        setScale(1);
      }
    };

    handleResize();
    window.addEventListener('resize', handleResize);

    // Dynamic ResizeObserver to continuously track dimensions (handles slow-loading fonts, images, etc.)
    const resizeObserver = new ResizeObserver(() => {
      if (receiptRef.current) {
        setReceiptHeight(receiptRef.current.scrollHeight);
      }
      if (evalRef.current) {
        setEvalHeight(evalRef.current.scrollHeight);
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

  return (
    <div id="print-wrapper-outer" className="min-h-screen bg-slate-50/50 print:bg-white py-6 md:py-10 px-4 print:p-0" dir="rtl" style={{ fontFamily: 'Cairo, sans-serif' }}>
      <div id="print-wrapper-inner" className="max-w-[832px] mx-auto print:w-full print:max-w-full">
        
        {/* CSS for print and scaling override */}
        <style dangerouslySetInnerHTML={{ __html: `
          @media print {
            @page { 
              margin: 0;
              size: A4 portrait;
            }
            
            /* Hide general web layout elements */
            header,
            nav,
            footer,
            .print\\:hidden,
            button {
              display: none !important;
            }

            /* Clean html and body margins/paddings */
            html, body {
              margin: 0 !important;
              padding: 0 !important;
              width: 100% !important;
              height: auto !important;
              background-color: white !important;
              -webkit-print-color-adjust: exact !important;
              print-color-adjust: exact !important;
            }

            /* Collapse Next.js layouts and wrapper spaces */
            body > div,
            main,
            main > div,
            #status-page-root,
            #status-content-wrapper,
            #form-inquiry-wrapper,
            #print-wrapper-outer,
            #print-wrapper-inner {
              margin: 0 !important;
              padding: 0 !important;
              width: 100% !important;
              max-width: none !important;
              min-height: 0 !important;
              height: auto !important;
              transform: none !important;
              box-shadow: none !important;
              background: none !important;
              display: block !important;
            }

            /* Hide all by default */
            body * {
              visibility: hidden;
            }

            /* Make only the printable components visible */
            #receipt, #receipt *,
            #evaluation-form, #evaluation-form * {
              visibility: visible;
            }

            /* Position printable components on their own pages */
            #receipt, #evaluation-form {
              position: relative !important;
              margin: 0 auto !important;
              padding: 0 !important;
              border: none !important;
              box-shadow: none !important;
              border-radius: 0 !important;
              width: 100% !important;
              max-width: 100% !important;
              page-break-inside: avoid;
            }

            #receipt {
              page-break-before: avoid;
              page-break-after: always;
            }

            #evaluation-form {
              page-break-before: always;
            }

            .print-no-scale {
              transform: none !important;
              width: 100% !important;
              height: auto !important;
            }
          }
        ` }} />

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
              className="flex-1 sm:flex-initial flex items-center justify-center gap-1.5 bg-emerald-600 hover:bg-emerald-700 disabled:bg-emerald-400 text-white font-bold text-xs sm:text-sm py-2.5 px-4 rounded-xl shadow-sm hover:shadow active:scale-95 transition-all cursor-pointer whitespace-nowrap"
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

        {isWaitlistMode ? (
          <div className="w-full max-w-[800px] mx-auto bg-amber-50 border border-amber-200 text-amber-800 p-3 rounded-xl mb-6 print:hidden text-center shadow-sm">
            <div className="flex items-center justify-center gap-2">
              <span className="text-xs font-extrabold">تم وضعك في قائمة الانتظار</span>
            </div>
            <p className="text-[11px] font-bold text-amber-700 mt-1">لقد اكتمل العدد الأساسي للمسابقة. سنتواصل معك في حال توفر مقعد لك.</p>
          </div>
        ) : null}

        {/* ── RECEIPT — مطابقة تامة لاستمارة الأدمن (Scaled Down on Screen to Fit viewport) ── */}
        <div 
          className="w-full flex justify-center overflow-x-auto overflow-y-visible print:block print:w-full print:h-auto print:overflow-visible mb-8 print:mb-0" 
          style={{ height: scale < 1 ? `${(receiptHeight + 16) * scale}px` : 'auto' }}
        >
          <div 
            id="receipt" 
            className="print-no-scale bg-white border border-slate-200 shadow-lg rounded-3xl print:border-none print:rounded-none print:shadow-none" 
            style={{ 
              transform: scale < 1 ? `scale(${scale})` : 'none', 
              transformOrigin: 'top center',
              width: 'min(800px, 100%)',
              fontFamily: '"Cairo", sans-serif', 
              direction: 'rtl' 
            }}
          >
            <div ref={receiptRef} style={{ padding: '20pt 24pt 24pt 24pt' }}>
              {/* ── HEADER ──── */}
              {/* ── HEADER ──── */}
              <div style={{ paddingBottom: '12pt', borderBottom: '2pt solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', flexDirection: 'column', flex: 1, paddingLeft: '16pt' }}>
                  <h1 style={{ color: 'var(--primary)', fontSize: '20pt', fontWeight: 900, margin: 0, lineHeight: 1.2, fontFamily: '"Cairo", sans-serif' }}>مسابقة أهل القرآن الكبرى</h1>
                  <p style={{ color: '#b45309', fontSize: '13pt', fontWeight: 700, margin: '4pt 0 0 0', lineHeight: 1.2, fontFamily: '"Cairo", sans-serif' }}>مقر اللجنة: مركز فاقوس - قرية الديدمون - شارع الشيخ - منزل المشرف العام</p>
                </div>
                <div style={{ width: '70pt', height: '70pt', borderRadius: '50%', overflow: 'hidden', flexShrink: 0 }}>
                  <img src="/logo_musapaka.jpeg" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
              </div>

              {/* ───── BODY ───── */}
              <div style={{ paddingTop: '16pt' }}>

                {/* ── INFO CARD ── */}
                <div style={{ border: '1pt solid #e2e8f0', borderRadius: '12pt', padding: '12pt', backgroundColor: 'white', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                    <div style={{ marginBottom: '8pt' }}><FlutterIconRow label="الاسم" value={formData.name} icon={<User size="12pt" color="white" />} /></div>
                    <div style={{ marginBottom: '8pt' }}><FlutterIconRow label="المستوى" value={`${formData.level} - ${getLevelContent()}${formData.selectedRewaya ? ' - ' + formData.selectedRewaya : ''}${branchName ? ' - ' + branchName : ''}`} icon={<Layers size="12pt" color="white" />} bgColor="#f59e0b" /></div>
                    <div style={{ marginBottom: '8pt' }}><FlutterIconRow label="موعد الامتحان" value={examSlot || 'لم يتم التحديد'} icon={<Calendar size="12pt" color="white" />} valueColor="#1e40af" /></div>
                    <FlutterIconRow label="العمر" value={`${formData.age} سنة`} icon={<User size="12pt" color="white" />} />
                  </div>

                  <div style={{ width: '90pt', minWidth: '90pt', marginRight: '20pt', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <div style={{ width: '90pt', height: '90pt', borderRadius: '50%', border: '2.5pt solid var(--primary)', overflow: 'hidden', backgroundColor: '#f5f3ef', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {profilePreview ? (
                        <img src={profilePreview} alt="Profile" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      ) : (
                        <img src="/logo_musapaka.jpeg" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      )}
                    </div>
                    <div style={{ marginTop: '10pt', padding: '4pt 12pt', backgroundColor: '#eeeeee', borderRadius: '16pt', display: 'flex', alignItems: 'center' }}>
                      <span style={{ fontSize: '11pt', fontWeight: 700, color: '#003527', fontFamily: "'Cairo', sans-serif" }}>{studentCode || formData.nationalId}</span>
                      <span style={{ marginRight: '4pt', display: 'flex' }}><User size="10pt" color="#003527" /></span>
                    </div>
                  </div>
                </div>

                <div style={{ height: '24pt' }} />

                {/* ── DETAILED DATA GRID ── */}
                <div style={{ position: 'relative', marginTop: '10pt' }}>
                  <div style={{ 
                    border: '1pt solid #e2e8f0', 
                    borderRadius: '12pt', 
                    overflow: 'hidden', 
                    direction: 'rtl',
                    display: 'grid',
                    gridTemplateColumns: '1fr 1fr',
                    backgroundColor: '#e2e8f0',
                    gap: '1px'
                  }}>
                    <FlutterGridCell label="الرقم القومي" value={formData.nationalId} icon={<CreditCard size="10pt" color="white" />} isTopRow={true} bg="#f5f3ef" />
                    <FlutterGridCell label="هاتف الطالب / ولي الأمر" value={formData.phone} icon={<Phone size="10pt" color="white" />} isTopRow={true} bg="#f5f3ef" />
                    
                    <FlutterGridCell label="تاريخ الميلاد" value={parseNationalId(formData.nationalId)?.birthDate ?? ''} icon={<Calendar size="10pt" color="white" />} />
                    <FlutterGridCell label="النوع" value={formData.gender} icon={<User size="10pt" color="white" />} />
                    
                    <FlutterGridCell label="المحفظ" value={formData.memorizerName || '-'} icon={<User size="10pt" color="white" />} bg="#f5f3ef" />
                    <FlutterGridCell label="هاتف المحفظ" value={formData.memorizerPhone || '-'} icon={<BookOpen size="10pt" color="white" />} bg="#f5f3ef" />
                    
                    <FlutterGridCell label="عنوان الطالب" value={formData.location || '-'} icon={<MapPin size="10pt" color="white" />} />
                    <FlutterGridCell label="عنوان المحفظ" value={formData.memorizerAddress || '-'} icon={<MapPin size="10pt" color="white" />} />
                  </div>
                  {/* Badge Overlay */}
                  <div style={{ position: 'absolute', top: 0, left: '50%', transform: 'translate(-50%, -50%)', backgroundColor: '#003527', padding: '4pt 12pt', borderRadius: '8pt', display: 'flex', alignItems: 'center' }}>
                    <div style={{ padding: '2pt', backgroundColor: '#003527', borderRadius: '4pt', display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 0 }}>
                      <List size="12pt" color="white" />
                    </div>
                    <span style={{ marginRight: '6pt', fontSize: '12pt', fontWeight: 700, color: 'white', fontFamily: '"Cairo", sans-serif' }}>البيانات التفصيلية</span>
                  </div>
                </div>

                <div style={{ height: '24pt' }} />

                {/* ── NOTES / CONDITIONS ── */}
                <div style={{ position: 'relative', marginTop: '10pt' }}>
                  <div style={{ border: '1pt solid #e2e8f0', borderRadius: '12pt', padding: '20pt 12pt 8pt 12pt', backgroundColor: '#f5f3ef' }}>
                    {[
                      'القبول بشروط المسابقة، يحظر تقديم أي رسوم مالية',
                      'كل متسابق يلتزم بالمواعيد المحدده له( التقديم -الاختبار-الحفلة)',
                      'يتم التصفيه في المسابقة بوضع سؤال للتصفية في الامتحان سؤال في ضبط المتشابهات',
                      'سيتم تكريم الاوائل الثلاثة على المنصة فقط والباقي في أماكنهم والرجاء الرضا بذالك',
                      'عند عدم الحضور المُكرم الحفل يحجب من الجائزة وتودع في الامانات',
                      'يحظر الجمع بين جائزتين فأكثر ،سيتم تكريم الفائزين بدرجة الامتياز فأكثر'
                    ].map((text, i) => (
                      <div key={i} style={{ display: 'flex', alignItems: 'flex-start', paddingBottom: '4pt' }}>
                        <div style={{ width: '20pt', height: '20pt', borderRadius: '50%', backgroundColor: '#003527', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: '2pt' }}>
                          <span style={{ fontSize: '11pt', fontWeight: 700, color: 'white', fontFamily: '"Cairo", sans-serif' }}>{i + 1}</span>
                        </div>
                        <span style={{ marginRight: '8pt', fontSize: '13pt', fontWeight: 400, color: '#003527', lineHeight: 1.4, textAlign: 'right', flex: 1, fontFamily: '"Cairo", sans-serif' }}>{text}</span>
                      </div>
                    ))}
                  </div>
                  {/* Badge Overlay */}
                  <div style={{ position: 'absolute', top: 0, left: '50%', transform: 'translate(-50%, -50%)', backgroundColor: 'white', padding: '4pt 12pt', borderRadius: '16pt', border: '1.5pt solid #f59e0b', display: 'flex', alignItems: 'center' }}>
                    <div style={{ padding: '3pt', backgroundColor: '#003527', borderRadius: '4pt', display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 0 }}>
                      <List size="10pt" color="white" />
                    </div>
                    <span style={{ marginRight: '6pt' }} />
                    <span style={{ fontSize: '12pt', fontWeight: 700, color: '#b45309', fontFamily: "'Cairo', sans-serif" }}>ملاحظات هامة</span>
                  </div>
                </div>

                <div style={{ height: '36pt' }} />

                {/* ── SUPERVISOR ── */}
                <div style={{ textAlign: 'center' }}>
                  <p style={{ color: '#b45309', fontSize: '11pt', fontWeight: 700, margin: 0, fontFamily: "'Cairo', sans-serif" }}>المشرف العام علي المسابقة</p>
                  <p style={{ color: '#003527', fontSize: '16pt', fontWeight: 700, margin: '2pt 0 0 0', fontFamily: "'Cairo', sans-serif" }}>أ/ مصطفى عبدالرحمن محمد سالم</p>
                </div>

                <div style={{ height: '24pt' }} />

                {/* ── FOOTER WARNING ── */}
                <div style={{ padding: '10pt 16pt', border: '2pt solid #f59e0b', borderRadius: '10pt', backgroundColor: '#fffbeb', display: 'flex', alignItems: 'center' }}>
                  <span style={{ color: '#b45309', display: 'flex', marginLeft: '10pt' }}><AlertTriangle size="18pt" /></span>
                  <span style={{ fontSize: '11pt', fontWeight: 700, color: '#92400e', marginLeft: '6pt', fontFamily: '"Cairo", sans-serif' }}>ملاحظة هامة:</span>
                  <span style={{ fontSize: '8.5pt', fontWeight: 700, color: '#92400e', flex: 1, fontFamily: '"Cairo", sans-serif' }}>يجب طباعة هذه الاستمارة في ورقة واحدة وإحضارها معك في موعد الاختبار المحدد لك أعلاه.</span>
                </div>

              </div>
            </div>
          </div>
        </div>

        {/* ── EVALUATION FORM — الصفحة الثانية (Scaled Down on Screen to Fit viewport) ── */}
        {(() => {
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

          return (
            <div 
              className="w-full flex justify-center overflow-x-auto overflow-y-visible print:block print:w-full print:h-auto print:overflow-visible mb-8 print:mb-0" 
              style={{ height: scale < 1 ? `${(evalHeight + 16) * scale}px` : 'auto' }}
            >
              <div 
                id="evaluation-form" 
                className="print-no-scale bg-white border border-slate-200 shadow-lg rounded-3xl print:border-none print:rounded-none print:shadow-none" 
                style={{ 
                  transform: scale < 1 ? `scale(${scale})` : 'none', 
                  transformOrigin: 'top center',
                  width: 'min(800px, 100%)',
                  fontFamily: '"Cairo", sans-serif', 
                  direction: 'rtl',
                  pageBreakBefore: 'always'
                }}
              >
                <div ref={evalRef} style={{ padding: '20pt 24pt 24pt 24pt' }}>

                  {/* Header */}
                  <div style={{ paddingBottom: '12pt', borderBottom: '2pt solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', flex: 1, paddingLeft: '16pt' }}>
                      <h2 style={{ color: '#003527', fontSize: '20pt', fontWeight: 700, margin: 0, lineHeight: 1.2, fontFamily: '"Cairo", sans-serif' }}>مسابقة أهل القرآن الكبرى</h2>
                      <p style={{ color: '#b45309', fontSize: '14pt', fontWeight: 700, margin: '4pt 0 0 0', lineHeight: 1, fontFamily: '"Cairo", sans-serif' }}>استمارة تقييم المتسابق</p>
                    </div>
                    <div style={{ width: '70pt', height: '70pt', borderRadius: '50%', overflow: 'hidden', flexShrink: 0 }}>
                      <img src="/logo_musapaka.jpeg" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    </div>
                  </div>

                  <div style={{ paddingTop: '16pt' }}>

                    {/* Student Mini Info */}
                    <div style={{ border: '1pt solid #e2e8f0', borderRadius: '8pt', padding: '12pt 16pt', backgroundColor: '#f5f3ef', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24pt' }}>
                      <span style={{ fontSize: '12pt', fontWeight: 700, color: '#003527', fontFamily: '"Cairo", sans-serif' }}>
                        الاسم: {formData.name}
                      </span>
                      <span style={{ fontSize: '12pt', fontWeight: 700, color: '#003527', fontFamily: '"Cairo", sans-serif', textAlign: 'left', flex: 1, marginRight: '16pt' }}>
                        {formData.level}{selLevel?.content ? ` - ${selLevel.content}` : ''}
                        {formData.selectedRewaya ? ` - ${formData.selectedRewaya}` : ''}
                        {branchName && (
                          <span style={{ color: '#dc2626' }}>{` (${branchName})`}</span>
                        )}
                      </span>
                    </div>

                    {/* Score Table */}
                    <div style={{ border: '1.5pt solid #003527', borderRadius: '8pt', overflow: 'hidden' }}>
                      <table style={{ width: '100%', borderCollapse: 'collapse', direction: 'rtl' }}>
                        <thead>
                          <tr style={{ backgroundColor: '#003527' }}>
                            <th style={{ width: '25%', padding: '8pt 10pt', textAlign: 'center', color: 'white', fontSize: '11pt', fontWeight: 700, fontFamily: '"Cairo", sans-serif', borderLeft: '1pt solid #334155' }}>الدرجة</th>
                            <th style={{ width: '45%', padding: '8pt 10pt', textAlign: 'center', color: 'white', fontSize: '11pt', fontWeight: 700, fontFamily: '"Cairo", sans-serif', borderLeft: '1pt solid #334155' }}>ملاحظات</th>
                            <th style={{ width: '30%', padding: '8pt 10pt', textAlign: 'center', color: 'white', fontSize: '11pt', fontWeight: 700, fontFamily: '"Cairo", sans-serif' }}>السؤال</th>
                          </tr>
                        </thead>
                        <tbody>
                          {questions.map((q, i) => (
                            <tr key={i} style={{ backgroundColor: i % 2 !== 0 ? '#f5f3ef' : 'white', borderTop: '1pt solid #e2e8f0' }}>
                              <td style={{ padding: '7pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '13pt', color: '#334155', fontFamily: 'monospace', paddingLeft: '20pt', borderLeft: '1pt solid #e2e8f0' }}>/ 10</td>
                              <td style={{ padding: '7pt 10pt', borderLeft: '1pt solid #e2e8f0', minWidth: '120pt' }}></td>
                              <td style={{ padding: '7pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '11pt', color: '#003527', fontFamily: '"Cairo", sans-serif', whiteSpace: 'nowrap' }}>{q}</td>
                            </tr>
                          ))}
                          {/* Questions subtotal */}
                          <tr style={{ backgroundColor: '#f1f5f9', borderTop: '2pt solid #94a3b8' }}>
                            <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '13pt', color: '#003527', fontFamily: 'monospace', paddingLeft: '20pt', borderLeft: '1pt solid #e2e8f0' }}>/ 100</td>
                            <td style={{ borderLeft: '1pt solid #e2e8f0' }}></td>
                            <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '11pt', color: '#003527', fontFamily: '"Cairo", sans-serif', whiteSpace: 'nowrap' }}>المجموع</td>
                          </tr>
                          {/* Rewaya */}
                          {hasRewaya && (
                            <tr style={{ backgroundColor: 'white', borderTop: '1pt solid #e2e8f0' }}>
                              <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '13pt', color: '#334155', fontFamily: 'monospace', paddingLeft: '24pt', borderLeft: '1pt solid #e2e8f0' }}>/ {rewayaScore}</td>
                              <td style={{ borderLeft: '1pt solid #e2e8f0' }}></td>
                              <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '11pt', color: '#003527', fontFamily: '"Cairo", sans-serif' }}>
                                الرواية{formData.selectedRewaya ? ` (${formData.selectedRewaya})` : ''}
                              </td>
                            </tr>
                          )}
                          {/* Tajweed */}
                          {hasTajweed && (
                            <tr style={{ backgroundColor: '#f5f3ef', borderTop: '1pt solid #e2e8f0' }}>
                              <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '13pt', color: '#334155', fontFamily: 'monospace', paddingLeft: '24pt', borderLeft: '1pt solid #e2e8f0' }}>/ {tajweedScore}</td>
                              <td style={{ borderLeft: '1pt solid #e2e8f0' }}></td>
                              <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '11pt', color: '#003527', fontFamily: '"Cairo", sans-serif' }}>التجويد</td>
                            </tr>
                          )}
                          {/* Voice */}
                          {hasVoice && (
                            <tr style={{ backgroundColor: 'white', borderTop: '1pt solid #e2e8f0' }}>
                              <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '13pt', color: '#334155', fontFamily: 'monospace', paddingLeft: '24pt', borderLeft: '1pt solid #e2e8f0' }}>/ {voiceScore}</td>
                              <td style={{ borderLeft: '1pt solid #e2e8f0' }}></td>
                              <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '11pt', color: '#003527', fontFamily: '"Cairo", sans-serif' }}>حسن الصوت</td>
                            </tr>
                          )}
                          {/* Meaning */}
                          {hasMeaning && (
                            <tr style={{ backgroundColor: '#f5f3ef', borderTop: '1pt solid #e2e8f0' }}>
                              <td style={{ padding: '8pt 10pt', textAlign: 'left', fontWeight: 700, fontSize: '13pt', color: '#334155', fontFamily: 'monospace', paddingLeft: '24pt', borderLeft: '1pt solid #e2e8f0' }}>/ {meaningScore}</td>
                              <td style={{ borderLeft: '1pt solid #e2e8f0' }}></td>
                              <td style={{ padding: '8pt 10pt', textAlign: 'center', fontWeight: 700, fontSize: '11pt', color: '#003527', fontFamily: '"Cairo", sans-serif' }}>فهم المعاني والوقف</td>
                            </tr>
                          )}
                          {/* Grand Total */}
                          <tr style={{ backgroundColor: '#fef3c7', borderTop: '2.5pt solid #003527' }}>
                            <td style={{ padding: '10pt 10pt', textAlign: 'left', fontWeight: 900, fontSize: '14pt', color: '#dc2626', fontFamily: 'monospace', paddingLeft: '20pt', borderLeft: '1pt solid #003527' }}>/ {grandTotal}</td>
                            <td style={{ borderLeft: '1pt solid #003527' }}></td>
                            <td style={{ padding: '10pt 10pt', textAlign: 'center', fontWeight: 900, fontSize: '12pt', color: '#003527', fontFamily: '"Cairo", sans-serif' }}>المجموع الكلي للقسم</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                    <div style={{ height: '24pt' }} />
                  </div>
                </div>
              </div>
            </div>
          );
        })()}

      </div>
    </div>
  );
}

