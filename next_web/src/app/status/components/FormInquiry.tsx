'use client';

import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import dynamic from 'next/dynamic';
import { motion, AnimatePresence } from 'framer-motion';
import { CreditCard, Search, ShieldCheck, AlertTriangle, Download, Printer, FileText, CheckCircle2, ArrowLeft } from 'lucide-react';
import type { CompetitionLevel, StudentStatus } from '@/lib/database.types';
import toast from 'react-hot-toast';

const Step5Success = dynamic(() => import('@/app/register/components/Step5Success'));

export default function FormInquiry() {
  const [mounted, setMounted] = useState(false);
  const [nationalId, setNationalId] = useState('');
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [notFound, setNotFound] = useState(false);
  const [studentData, setStudentData] = useState<StudentStatus | null>(null);
  const [levels, setLevels] = useState<CompetitionLevel[]>([]);
  const [isCapturing, setIsCapturing] = useState(false);

  useEffect(() => { queueMicrotask(() => setMounted(true)); }, []);

  const idValid = nationalId.length === 14;
  const canSubmit = idValid && !loading;

  const handleInquiry = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idValid) { setError('الرقم القومي يجب أن يتكون من 14 رقماً'); return; }

    setError('');
    setNotFound(false);
    setLoading(true);
    setSearched(true);
    setStudentData(null);

    try {
      const response = await fetch('/api/inquiry', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nationalId }),
      });
      const data = await response.json();
      if (!response.ok) {
        const msg = data.error || 'حدث خطأ أثناء الاستعلام';
        if (msg.includes('غير موجود') || msg.includes('يوجد') || msg.includes('العثور')) {
          setNotFound(true);
        } else {
          setError(msg);
        }
        return;
      }
      setStudentData(data.student);
      setLevels(data.levels);
    } catch {
      setError('فشل الاتصال بالخادم. يرجى المحاولة مرة أخرى.');
    } finally {
      setLoading(false);
    }
  };

  const handleNewSearch = () => {
    setStudentData(null); setSearched(false); setError(''); setNotFound(false);
    setNationalId('');
  };

  const captureBoth = async (): Promise<{ receiptCanvas: HTMLCanvasElement | null; evalCanvas: HTMLCanvasElement | null }> => {
    const receiptEl = document.getElementById('receipt');
    const evalEl = document.getElementById('evaluation-form');

    const parent = (receiptEl || evalEl)?.closest('.hidden.print\\:block') as HTMLElement | null;
    const wasHidden = parent ? parent.classList.contains('hidden') : false;

    if (wasHidden && parent) {
      parent.classList.remove('hidden');
      parent.style.position = 'absolute';
      parent.style.left = '-9999px';
      parent.style.top = '0';
      parent.style.width = '800px';
      parent.style.visibility = 'visible';
      parent.style.zIndex = '-1';
      parent.style.display = 'block';
    }

    [receiptEl, evalEl].forEach(el => {
      if (el) { el.style.display = 'block'; el.style.visibility = 'visible'; }
    });

    await new Promise(r => setTimeout(r, 200));

    const html2canvas = (await import('html2canvas-pro')).default;

    const makeOnclone = (id: string) => (clonedDoc: Document) => {
      const clonedEl = clonedDoc.getElementById(id);
      if (!clonedEl) return;
      clonedEl.style.display = 'block';
      clonedEl.style.visibility = 'visible';
      clonedEl.style.width = '800px';
      clonedEl.style.height = 'auto';
      clonedEl.style.maxHeight = 'none';
      clonedEl.style.overflow = 'visible';
      let p: HTMLElement | null = clonedEl.parentElement;
      while (p && p !== clonedDoc.body) {
        p.style.display = 'block';
        p.style.visibility = 'visible';
        p.style.width = '800px';
        p.style.height = 'auto';
        p.style.maxHeight = 'none';
        p.style.overflow = 'visible';
        p.style.position = 'static';
        p.style.left = 'auto';
        p.style.top = 'auto';
        p.style.zIndex = 'auto';
        p = p.parentElement;
      }
    };

    let receiptCanvas: HTMLCanvasElement | null = null;
    let evalCanvas: HTMLCanvasElement | null = null;

    try {
      if (receiptEl) {
        receiptCanvas = await html2canvas(receiptEl, {
          scale: 2,
          useCORS: true,
          backgroundColor: '#ffffff',
          logging: false,
          windowWidth: 850,
          windowHeight: Math.min(receiptEl.scrollHeight + 200, 6000),
          onclone: makeOnclone('receipt'),
        });
      }

      if (evalEl) {
        evalCanvas = await html2canvas(evalEl, {
          scale: 2,
          useCORS: true,
          backgroundColor: '#ffffff',
          logging: false,
          windowWidth: 850,
          windowHeight: Math.min(evalEl.scrollHeight + 200, 6000),
          onclone: makeOnclone('evaluation-form'),
        });
      }
    } finally {
      [receiptEl, evalEl].forEach(el => {
        if (el) { el.style.display = ''; el.style.visibility = ''; }
      });

      if (wasHidden && parent) {
        parent.classList.add('hidden');
        parent.style.position = '';
        parent.style.left = '';
        parent.style.top = '';
        parent.style.width = '';
        parent.style.visibility = '';
        parent.style.zIndex = '';
        parent.style.display = '';
      }
    }

    return { receiptCanvas, evalCanvas };
  };

  const captureElement = async (id: string): Promise<HTMLCanvasElement | null> => {
    const el = document.getElementById(id);
    if (!el) return null;

    const parent = el.closest('.hidden.print\\:block') as HTMLElement | null;
    const wasHidden = parent ? parent.classList.contains('hidden') : false;

    const originalDisplay = el.style.display;
    const originalVisibility = el.style.visibility;

    if (wasHidden && parent) {
      parent.classList.remove('hidden');
      parent.style.position = 'absolute';
      parent.style.left = '-9999px';
      parent.style.top = '0';
      parent.style.width = '800px';
      parent.style.visibility = 'visible';
      parent.style.zIndex = '-1';
      parent.style.display = 'block';
    }

    el.style.display = 'block';
    el.style.visibility = 'visible';

    await new Promise(r => setTimeout(r, 150));

    try {
      const html2canvas = (await import('html2canvas-pro')).default;
      const canvas = await html2canvas(el, {
        scale: 2,
        useCORS: true,
        backgroundColor: '#ffffff',
        logging: false,
        windowWidth: 850,
        windowHeight: Math.min(el.scrollHeight + 200, 6000),
        onclone: (clonedDoc) => {
          const clonedEl = clonedDoc.getElementById(id);
          if (!clonedEl) return;
          clonedEl.style.display = 'block';
          clonedEl.style.visibility = 'visible';
          clonedEl.style.width = '800px';
          clonedEl.style.height = 'auto';
          clonedEl.style.maxHeight = 'none';
          clonedEl.style.overflow = 'visible';
          let p: HTMLElement | null = clonedEl.parentElement;
          while (p && p !== clonedDoc.body) {
            p.style.display = 'block';
            p.style.visibility = 'visible';
            p.style.width = '800px';
            p.style.height = 'auto';
            p.style.maxHeight = 'none';
            p.style.overflow = 'visible';
            p.style.position = 'static';
            p.style.left = 'auto';
            p.style.top = 'auto';
            p.style.zIndex = 'auto';
            p = p.parentElement;
          }
        },
      });
      return canvas;
    } finally {
      el.style.display = originalDisplay;
      el.style.visibility = originalVisibility;

      if (wasHidden && parent) {
        parent.classList.add('hidden');
        parent.style.position = '';
        parent.style.left = '';
        parent.style.top = '';
        parent.style.width = '';
        parent.style.visibility = '';
        parent.style.zIndex = '';
        parent.style.display = '';
      }
    }
  };

  const handleDownloadImage = async () => {
    setIsCapturing(true);
    const toastId = toast.loading('جاري تجهيز الاستمارات...');
    try {
      const { receiptCanvas, evalCanvas } = await captureBoth();
      if (!receiptCanvas) throw new Error('الاستمارة غير موجودة');

      toast.loading('جاري تحميل استمارة البيانات...', { id: toastId });
      const dataUrl = receiptCanvas.toDataURL('image/jpeg', 0.85);
      const link = document.createElement('a');
      link.href = dataUrl;
      link.download = `استمارة_${studentData?.name?.replace(/\s+/g, '_') || 'student'}.jpg`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      if (evalCanvas) {
        await new Promise(r => setTimeout(r, 800));
        toast.loading('جاري تحميل استمارة التقييم...', { id: toastId });
        const dataUrl2 = evalCanvas.toDataURL('image/jpeg', 0.85);
        const link2 = document.createElement('a');
        link2.href = dataUrl2;
        link2.download = `استمارة_تقييم_${studentData?.name?.replace(/\s+/g, '_') || 'student'}.jpg`;
        document.body.appendChild(link2);
        link2.click();
        document.body.removeChild(link2);
      }

      toast.success('تم تحميل الملفات', { id: toastId, duration: 4000 });
    } catch (err) {
      console.error(err);
      toast.error('فشل تجهيز الاستمارة — حاول مرة أخرى', { id: toastId });
    } finally {
      setIsCapturing(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  const handleDownloadPdf = async () => {
    setIsCapturing(true);
    const toastId = toast.loading('جاري تجهيز ملف PDF...');
    try {
      const jsPdfModule = await import('jspdf');
      const jsPDF = jsPdfModule.default;

      const { receiptCanvas, evalCanvas } = await captureBoth();
      if (!receiptCanvas) throw new Error('الاستمارة غير موجودة');

      const pdf = new jsPDF('p', 'mm', 'a4');
      const pdfWidth = pdf.internal.pageSize.getWidth();
      const pdfHeight = pdf.internal.pageSize.getHeight();

      const receiptHeight = (receiptCanvas.height * pdfWidth) / receiptCanvas.width;
      const receiptData = receiptCanvas.toDataURL('image/jpeg', 0.92);
      pdf.addImage(receiptData, 'JPEG', 0, 0, pdfWidth, Math.min(receiptHeight, pdfHeight));

      if (evalCanvas) {
        const evalHeight = (evalCanvas.height * pdfWidth) / evalCanvas.width;
        const evalData = evalCanvas.toDataURL('image/jpeg', 0.92);
        pdf.addPage();
        pdf.addImage(evalData, 'JPEG', 0, 0, pdfWidth, Math.min(evalHeight, pdfHeight));
      }

      const pdfFilename = `استمارة_${studentData?.name?.replace(/\s+/g, '_') || 'student'}.pdf`;
      const pdfBlob = pdf.output('blob');
      const pdfUrl = URL.createObjectURL(pdfBlob);
      const link = document.createElement('a');
      link.href = pdfUrl;
      link.download = pdfFilename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      setTimeout(() => URL.revokeObjectURL(pdfUrl), 1000);

      toast.success('تم تحميل الملف', { id: toastId, duration: 4000 });
    } catch (err) {
      console.error(err);
      toast.error('فشل حفظ PDF', { id: toastId });
    } finally {
      setIsCapturing(false);
    }
  };

  if (studentData) {
    const formData = {
      name: studentData.name,
      phone: studentData.phone || '',
      nationalId: studentData.national_id || '',
      birthDate: studentData.birth_date || '',
      gender: studentData.gender || '',
      memorizerName: studentData.memorizer_name || '',
      memorizerPhone: studentData.memorizer_phone || '',
      memorizerAddress: studentData.memorizer_address || '',
      location: studentData.location || '',
      level: studentData.level,
      selectedRewaya: studentData.selected_rewaya || '',
    };
    const getLevelContent = () => levels.find(l => l.title === studentData.level)?.content ?? '';
    const examSlot = (() => {
      if (!studentData.exam_date || studentData.exam_hour === null || studentData.exam_hour === undefined) return '';
      try {
        const date = new Date(studentData.exam_date);
        const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
        const dayName = days[date.getDay()];
        const dateOnly = studentData.exam_date.split('T')[0];

        let timeStr = `${studentData.exam_hour}:00`;
        const h = Number(studentData.exam_hour);
        if (!isNaN(h)) {
          if (h === 0) timeStr = '12 منتصف الليل';
          else if (h < 12) timeStr = `${h} صباحاً`;
          else if (h === 12) timeStr = '12 ظهراً';
          else timeStr = `${h - 12} مساءً`;
        }

        return `يوم ${dayName} الموافق ${dateOnly} - الساعة ${timeStr}`;
      } catch {
        return '';
      }
    })();

    return (
      <>
        {isCapturing && (
          <div className="fixed inset-0 z-[99999] bg-black/50 flex items-center justify-center" style={{ backdropFilter: 'blur(4px)' }}>
            <div className="bg-white rounded-2xl px-8 py-6 shadow-xl text-center max-w-md">
              <div className="w-10 h-10 border-3 border-primary/25 border-t-primary rounded-full animate-spin mx-auto mb-4" />
              <p className="text-sm font-bold text-on-surface">جاري تجهيز الاستمارة</p>
              <p className="text-xs font-semibold text-on-surface-variant/60 mt-1">يرجى الانتظار قليلاً...</p>
            </div>
          </div>
        )}

        <motion.div
          initial={{ opacity: 0, y: 20, scale: 0.97 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
          className="max-w-lg mx-auto print:hidden"
        >
          <div className="w-16 h-16 bg-secondary-fixed/30 rounded-full flex items-center justify-center mx-auto mb-5">
            <CheckCircle2 size={36} className="text-secondary" />
          </div>

          <h2 className="text-2xl sm:text-3xl font-black text-primary text-center mb-3">
            {studentData.name}
          </h2>
          <p className="text-sm font-bold text-on-surface-variant text-center leading-relaxed mb-6">
            {studentData.level}<br />
            يمكنك الآن تحميل استمارة التسجيل كصورة أو طباعتها أو حفظها كملف PDF.
          </p>

          <div className="flex flex-col sm:flex-row gap-3 mb-6">
            <button
              onClick={handleDownloadImage}
              disabled={isCapturing}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-secondary text-white text-sm font-bold hover:bg-secondary/85 active:scale-95 transition-all shadow-sm disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
            >
              <Download size={16} />
              <span>{isCapturing ? 'جاري...' : 'تحميل كصورة'}</span>
            </button>

            <button
              onClick={handlePrint}
              disabled={isCapturing}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-primary text-white text-sm font-bold hover:bg-primary/85 active:scale-95 transition-all shadow-sm disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
            >
              <Printer size={16} />
              <span>طباعة</span>
            </button>

            <button
              onClick={handleDownloadPdf}
              disabled={isCapturing}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-slate-800 text-white text-sm font-bold hover:bg-slate-700 active:scale-95 transition-all shadow-sm disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
            >
              <FileText size={16} />
              <span>{isCapturing ? 'جاري...' : 'حفظ PDF'}</span>
            </button>
          </div>

          <div className="text-center">
            <button
              onClick={handleNewSearch}
              className="inline-flex items-center gap-1.5 text-xs font-bold text-on-surface-variant hover:text-primary transition-colors cursor-pointer"
            >
              <ArrowLeft size={14} />
              استعلام جديد
            </button>
          </div>
        </motion.div>

        {mounted && createPortal(
          <div className="hidden print:block">
            <Step5Success
              formData={formData} levels={levels} getLevelContent={getLevelContent}
              examSlot={examSlot} profilePreview={studentData.profile_image_url || null}
              birthCertPreview={studentData.birth_certificate_url || null}
              studentCode={studentData.student_code || ''}
              branchName={studentData.branch_name || ''}
              memorizationAmount={studentData.memorization_amount ?? null}
              onNewSearch={handleNewSearch}
            />
          </div>,
          document.body
        )}
      </>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.3, ease: 'easeOut' }}
      className="w-full max-w-lg mx-auto"
    >
      {/* Heading */}
      <div className="text-center mb-8">
        <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mx-auto mb-4">
          <ShieldCheck size={22} className="text-primary" />
        </div>
        <h1 className="text-xl sm:text-2xl font-black text-primary">
          استعلام الاستمارة وموعد الاختبار
        </h1>
        <p className="text-sm sm:text-base text-on-surface-variant/70 mt-2 font-semibold">
          أدخل الرقم القومي لعرض استمارة القبول وموعد الاختبار
        </p>
      </div>

      {/* Not found */}
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
            <p className="text-amber-700 text-xs font-semibold">تأكد من صحة الرقم القومي المدخل</p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Form */}
      <form onSubmit={handleInquiry} dir="rtl">
        <div className="space-y-5">
          <div>
            <label className="block text-sm font-bold text-on-surface mb-2">
              الرقم القومي
              <span className="text-red-400 mr-1">*</span>
            </label>
            <div className="relative">
              <input
                type="text"
                inputMode="numeric"
                maxLength={14}
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

          <button
            type="submit"
            disabled={!canSubmit}
            className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-bold text-sm text-white bg-primary hover:bg-primary/90 active:scale-[0.98] transition-all disabled:opacity-40 disabled:cursor-not-allowed disabled:active:scale-100 shadow-sm"
          >
            {loading ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <><Search size={16} /><span>عرض الاستمارة</span></>
            )}
          </button>
        </div>
      </form>

      <p className="text-center text-xs text-on-surface-variant/40 mt-6 font-semibold">
        في حالة وجود أي استفسار، يرجى التواصل مع إدارة المسابقة
      </p>
    </motion.div>
  );
}
