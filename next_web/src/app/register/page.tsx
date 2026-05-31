'use client';
/* Deployment trigger: 2026-05-19T23:36:27Z */
import React, { useState, useEffect, useMemo, useRef } from 'react';
import { getSupabase } from '@/lib/supabase';
import { CheckCircle2, ChevronLeft, ChevronRight, ShieldCheck, ArrowLeft, Send, CalendarX, Download, Printer, FileText } from 'lucide-react';
import { toast } from 'react-hot-toast';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import type { CompetitionLevel } from '@/lib/database.types';

// Subcomponents
import Step1Personal from './components/Step1Personal';
import Step2Level from './components/Step3Level';
import Step3Review from './components/Step4Review';
import Step4Success from './components/Step5Success';

/** Avoid UTC midnight shifting the calendar day */
function parseLocalDateOnly(iso: string) {
  const part = iso.split('T')[0] ?? iso;
  const [y, m, d] = part.split('-').map(Number);
  return new Date(y, m - 1, d);
}

function isRegistrationOpenAllowed(row: {
  is_registration_open?: boolean | null;
  registration_start_date?: string | null;
  registration_end_date?: string | null;
}) {
  if (row.is_registration_open === false) return false;
  const today = new Date();
  const t0 = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  if (row.registration_start_date) {
    const s = parseLocalDateOnly(row.registration_start_date);
    if (t0 < s) return false;
  }
  if (row.registration_end_date) {
    const e = parseLocalDateOnly(row.registration_end_date);
    if (t0 > e) return false;
  }
  return true;
}

export default function RegisterPage() {
  const searchParams = useSearchParams();
  const [loading, setLoading] = useState(false);
  const [levels, setLevels] = useState<CompetitionLevel[]>([]);
  const [success, setSuccess] = useState(false);
  const [isConfirmed, setIsConfirmed] = useState(false);
  const [registrationAllowed, setRegistrationAllowed] = useState(true);
  const [isWaitlistMode, setIsWaitlistMode] = useState(false);
  const [capacityFull, setCapacityFull] = useState(false);

  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({ name: '', phone: '', nationalId: '', age: '', memorizerName: '', memorizerPhone: '', memorizerAddress: '', location: '', gender: '', level: '', selectedRewaya: '' });
  const [branchName, setBranchName] = useState('');
  const [memorizationAmount, setMemorizationAmount] = useState<number | null>(null);
  const [honeypot, setHoneypot] = useState(''); // Honeypot field to catch bots
  const [profileImage, setProfileImage] = useState<File | null>(null);
  const [birthCertImage, setBirthCertImage] = useState<File | null>(null);
  const [profilePreview, setProfilePreview] = useState<string | null>(null);
  const [birthCertPreview, setBirthCertPreview] = useState<string | null>(null);
  const [studentCode, setStudentCode] = useState('');
  const [examDate, setExamDate] = useState<string | null>(null);
  const [examHour, setExamHour] = useState<number | null>(null);
  const [nameExists, setNameExists] = useState(false);
  const [isCheckingName, setIsCheckingName] = useState(false);
  const [idExists, setIdExists] = useState(false);
  const [isCheckingId, setIsCheckingId] = useState(false);
  const [turnstileToken, setTurnstileToken] = useState<string | null>(
    process.env.NODE_ENV === 'development' ? 'dev-bypass-token' : null
  );
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [levelCounts, setLevelCounts] = useState<Record<string, number>>({});
  const [isCapturing, setIsCapturing] = useState(false);
  const hiddenFormRef = useRef<HTMLDivElement>(null);
  const clearErr = (key: string) => setFieldErrors(p => { if (!p[key]) return p; const n = { ...p }; delete n[key]; return n; });

  const steps = [
    { num: 1, label: 'البيانات الشخصية' },
    { num: 2, label: 'مستوى المسابقة' },
    { num: 3, label: 'مراجعة البيانات' },
  ];

  useEffect(() => {
    const handler = setTimeout(async () => {
      if (formData.name.trim().length < 3) {
        setNameExists(false);
        return;
      }
      setIsCheckingName(true);
      const { data } = await getSupabase()
        .from('students')
        .select('id')
        .eq('name', formData.name.trim())
        .maybeSingle();

      setNameExists(!!data);
      setIsCheckingName(false);
    }, 800);

    return () => clearTimeout(handler);
  }, [formData.name]);

  useEffect(() => {
    const handler = setTimeout(async () => {
      if (formData.nationalId.trim().length !== 14) {
        setIdExists(false);
        return;
      }
      setIsCheckingId(true);
      const { data } = await getSupabase()
        .from('students')
        .select('id')
        .eq('national_id', formData.nationalId.trim())
        .maybeSingle();

      setIdExists(!!data);
      setIsCheckingId(false);
    }, 500);

    return () => clearTimeout(handler);
  }, [formData.nationalId]);

  useEffect(() => {
    const load = async () => {
      const countsMap: Record<string, number> = {};
      try {
        const { count: studentCount, error: countErr } = await getSupabase()
          .from('students')
          .select('*', { count: 'exact', head: true });

        if (countErr) {
          console.error("Error fetching student count:", countErr);
        }
        const count = studentCount ?? 0;

        const { data } = await getSupabase()
          .from('app_settings')
          .select('is_registration_open, registration_start_date, registration_end_date, exam_schedule')
          .eq('id', 1)
          .single();
          
        if (data) {
          let totalCap = 0;
          if (data.exam_schedule && Array.isArray(data.exam_schedule)) {
            for (const slot of data.exam_schedule as Array<Record<string, unknown>>) {
              const s = (slot.start_hour as number) || 8;
              const e = (slot.end_hour as number) || 13;
              const bg = (slot.students_per_hour as number) || 4;
              totalCap += (e - s) * bg;
            }
          }

          if (totalCap > 0 && count >= totalCap) {
            setIsWaitlistMode(false);
            setRegistrationAllowed(false);
            setCapacityFull(true);
          } else {
            setRegistrationAllowed(isRegistrationOpenAllowed(data));
            setCapacityFull(false);
          }
        }
      } catch (err) {
        console.error("Error loading settings:", err);
      }

      try {
        const { data: stdLevels } = await getSupabase().from('students').select('level');
        stdLevels?.forEach(s => {
          countsMap[s.level] = (countsMap[s.level] || 0) + 1;
        });
        setLevelCounts(countsMap);
      } catch (err) {
        console.error("Error loading level counts:", err);
      }

      try {
        const { data: lvls } = await getSupabase().from('competition_levels').select('*').eq('is_active', true).order('level_code');
        if (lvls?.length) {
          setLevels(lvls);
          const preselected = searchParams.get('level');
          if (preselected && lvls.some(l => l.title === preselected)) {
            setFormData(p => ({ ...p, level: preselected }));
          } else {
            setFormData(p => ({ ...p, level: '', selectedRewaya: '' }));
          }
        }
      } catch (err) {
        console.error("Error loading levels:", err);
      }
    };
    load();
  }, [searchParams]);

  const extractedInfo = useMemo(() => {
    const id = formData.nationalId.trim();
    if (id.length === 14 && /^\d+$/.test(id)) {
      const c = parseInt(id[0]);
      if (c === 2 || c === 3) {
        const y = (c === 2 ? 1900 : 2000) + parseInt(id.substring(1, 3));
        const m = parseInt(id.substring(3, 5)), d = parseInt(id.substring(5, 7));
        const bd = new Date(y, m - 1, d), now = new Date();
        let age = now.getFullYear() - bd.getFullYear();
        if (now.getMonth() < bd.getMonth() || (now.getMonth() === bd.getMonth() && now.getDate() < bd.getDate())) age--;
        const isMale = parseInt(id[12]) % 2 !== 0;
        return { birthDate: `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`, age, isMale, isValid: true };
      }
    }
    return { birthDate: '', age: null, isMale: null, isValid: false };
  }, [formData.nationalId]);

  const handleImagePick = (e: React.ChangeEvent<HTMLInputElement>, type: 'profile' | 'birthCert') => {
    const file = e.target.files?.[0]; if (!file) return;
    const url = URL.createObjectURL(file);
    if (type === 'profile') { setProfileImage(file); setProfilePreview(url); clearErr('profile'); }
    else { setBirthCertImage(file); setBirthCertPreview(url); clearErr('birthCert'); }
  };

  const compressImage = async (file: File): Promise<Blob> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = (event) => {
        const img = new Image();
        img.src = event.target?.result as string;
        img.onload = () => {
          const canvas = document.createElement('canvas');
          const MAX_WIDTH = 1200;
          const MAX_HEIGHT = 1200;
          let width = img.width;
          let height = img.height;

          if (width > height) {
            if (width > MAX_WIDTH) {
              height *= MAX_WIDTH / width;
              width = MAX_WIDTH;
            }
          } else {
            if (height > MAX_HEIGHT) {
              width *= MAX_HEIGHT / height;
              height = MAX_HEIGHT;
            }
          }

          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d');
          ctx?.drawImage(img, 0, 0, width, height);
          canvas.toBlob(
            (blob) => {
              if (blob) resolve(blob);
              else reject(new Error('Compression failed'));
            },
            'image/jpeg',
            0.7
          );
        };
      };
      reader.onerror = (err) => reject(err);
    });
  };

  const uploadToCloudinary = async (fileOrBlob: File | Blob) => {
    const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;
    const uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET;

    if (!cloudName || !uploadPreset) {
      console.error('Cloudinary configuration is missing');
      throw new Error('إعدادات السحابة غير صحيحة. يرجى التواصل مع الإدارة.');
    }

    const fd = new FormData();
    fd.append('file', fileOrBlob);
    fd.append('upload_preset', uploadPreset);

    try {
      const r = await fetch(`https://api.cloudinary.com/v1_1/${cloudName}/image/upload`, {
        method: 'POST',
        body: fd
      });

      const res = await r.json();
      if (!r.ok) {
        console.error('Cloudinary upload error:', res);
        throw new Error(res.error?.message || 'فشل في الرفع');
      }
      return res.secure_url;
    } catch (err) {
      console.error('Upload failed:', err);
      throw err;
    }
  };

  const nextStep = () => {
    const errs: Record<string, string> = {};
    if (step === 1) {
      if (!formData.name.trim()) errs.name = 'حقل الاسم';
      else if (formData.name.trim().split(/\s+/).length < 4) errs.name = 'الاسم يجب أن يتكون من 4 أجزاء على الأقل';
      if (!formData.phone.trim()) errs.phone = 'حقل الهاتف مطلوب';
      else if (!/^(010|011|012|015)\d{8}$/.test(formData.phone.trim())) errs.phone = 'رقم الهاتف غير صحيح';
      if (!formData.location.trim()) errs.location = 'حقل العنوان';
      if (!profileImage) errs.profile = 'الصورة الشخصية مطلوبة';
      if (!extractedInfo.isValid) errs.nationalId = 'الرقم القومي غير صحيح';
      if (parseInt(formData.age) !== extractedInfo.age) errs.age = 'العمر غير صحيح';
      if (!formData.gender) errs.gender = 'حقل النوع مطلوب';
      else if (extractedInfo.isMale !== null) {
        const expected = extractedInfo.isMale ? 'ذكر' : 'أنثى';
        if (formData.gender !== expected) errs.gender = 'النوع لا يتطابق مع الرقم القومي';
      }
      if (!birthCertImage) errs.birthCert = 'شهادة الميلاد مطلوبة';
      setFieldErrors(errs);
      if (Object.keys(errs).length) return toast.error(Object.values(errs)[0]);
      setStep(2); window.scrollTo({ top: 0, behavior: 'smooth' });
    } else if (step === 2) {
      if (!formData.level) errs.level = 'حقل المستوى';
      const selLevel = levels.find(l => l.title === formData.level);
      if (selLevel?.has_rewaya && selLevel.available_rewayas?.length && !formData.selectedRewaya) {
        errs.rewaya = 'يجب اختيار الرواية';
        toast.error('يرجى اختيار الرواية المناسبة');
      }
      if (selLevel?.branches && selLevel.branches.length > 0 && !branchName) {
        errs.branch = 'يجب اختيار الفرع / القسم';
        toast.error('يرجى اختيار الفرع المناسب');
      }
      if (selLevel?.require_custom_amount && memorizationAmount == null) {
        errs.branch = 'يجب إدخال كمية الحفظ';
        toast.error('يرجى إدخال كمية الحفظ بالأجزاء');
      }
      setFieldErrors(errs);
      if (Object.keys(errs).length) return toast.error(Object.values(errs)[0]);
      setStep(3); window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  const getLevelContent = () => {
    const found = levels.find(l => l.title === formData.level);
    return found ? found.content : '';
  };

  const examSlot = useMemo(() => {
    if (!examDate || examHour === null || examHour === undefined) return '';
    try {
      const date = new Date(examDate);
      const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      const dayName = days[date.getDay()];
      const dateOnly = examDate.split('T')[0];

      let timeStr = `${examHour}:00`;
      const h = Number(examHour);
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
  }, [examDate, examHour]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (honeypot) return;

    const lastSub = localStorage.getItem('last_reg_time');
    const now = Date.now();
    if (lastSub && now - parseInt(lastSub) < 30000) {
      return toast.error('يرجى الانتظار قليلاً قبل إرسال طلب آخر');
    }

    if (!turnstileToken) {
      return toast.error('يرجى إكمال التحقق الأمني (Turnstile)');
    }

    if (!formData.memorizerName.trim()) return toast.error('اسم المحفظ مطلوب');

    if (formData.phone.trim() && formData.memorizerPhone.trim() && formData.phone.trim() === formData.memorizerPhone.trim()) {
      return toast.error('لا يمكن استخدام نفس رقم هاتف الطالب وولي الأمر');
    }

    const selLevel = levels.find(l => l.title === formData.level);
    if (selLevel && selLevel.max_capacity != null) {
      const count = levelCounts[selLevel.title] || 0;
      if (count >= selLevel.max_capacity) {
        return toast.error('عذراً، هذا المستوى ممتلئ تماماً ولا يمكن قبول تسجيلات جديدة فيه.');
      }
    }

    setLoading(true);
    const uploadToast = toast.loading('جاري تجهيز بيانات التسجيل...');

    try {
      const [profileUrl, birthUrl] = await (async () => {
            const [profileBlob, birthBlob] = await Promise.all([
              profileImage ? compressImage(profileImage) : Promise.resolve(null),
              birthCertImage ? compressImage(birthCertImage) : Promise.resolve(null),
            ]);

            const [pUrl, bUrl] = await Promise.all([
              profileBlob ? uploadToCloudinary(profileBlob) : Promise.resolve(null),
              birthBlob ? uploadToCloudinary(birthBlob) : Promise.resolve(null),
            ]);
            return [pUrl, bUrl];
          })();

      const res = await fetch('/api/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          token: turnstileToken,
          website_url_verification: honeypot,
          name: formData.name.trim(),
          phone: formData.phone.trim(),
          national_id: formData.nationalId.trim(),
          level: formData.level,
          age: extractedInfo.age,
          gender: formData.gender,
          profile_image_url: profileUrl,
          birth_certificate_url: birthUrl,
          memorizer_name: formData.memorizerName.trim(),
          memorizer_phone: formData.memorizerPhone.trim(),
          memorizer_address: formData.memorizerAddress.trim(),
          location: formData.location.trim(),
          birth_date: extractedInfo.birthDate,
          selected_rewaya: formData.selectedRewaya || null,
          branch_name: branchName.trim() || null,
          memorization_amount: memorizationAmount,
        }),
      });

      const result = await res.json();
      toast.dismiss(uploadToast);

      if (!res.ok) {
        throw new Error(result.error || 'فشل التسجيل');
      }

      setStudentCode(result.data.student_code);
      setExamDate(result.data.exam_date);
      setExamHour(result.data.exam_hour);

      localStorage.setItem('last_reg_time', Date.now().toString());
      toast.success('تم التسجيل بنجاح!');
      setSuccess(true);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } catch (err: unknown) {
      toast.dismiss(uploadToast);
      console.error('Registration error:', err);
      toast.error(err instanceof Error ? err.message : 'حدث خطأ غير متوقع');
    } finally {
      setLoading(false);
    }
  };

  // -- CAPTURE / DOWNLOAD HANDLERS -------------------------------------
  const showFormTemporarily = async (): Promise<boolean> => {
    const container = hiddenFormRef.current;
    if (!container) return false;
    container.style.display = 'block';
    container.style.position = 'absolute';
    container.style.left = '-9999px';
    container.style.top = '0';
    container.style.zIndex = '9999';
    document.body.style.overflowX = 'hidden';
    await new Promise(r => requestAnimationFrame(() => setTimeout(r, 100)));
    return true;
  };

  const hideForm = () => {
    const container = hiddenFormRef.current;
    if (!container) return;
    container.style.display = '';
    container.style.position = '';
    container.style.left = '';
    container.style.top = '';
    container.style.zIndex = '';
    document.body.style.overflowX = '';
  };

  const yieldToUi = () => new Promise(r => setTimeout(r, 0));

  const handleDownloadImage = async () => {
    setIsCapturing(true);
    await yieldToUi();
    const toastId = toast.loading('جاري تجهيز الاستمارة...');
    try {
      await showFormTemporarily();

      const receiptCanvas = await captureElement('receipt');
      if (!receiptCanvas) throw new Error('الاستمارة غير موجودة');
      await yieldToUi();

      const link = document.createElement('a');
      link.href = receiptCanvas.toDataURL('image/png');
      link.download = `استمارة_${formData.name.replace(/\s+/g, '_')}.png`;
      link.click();

      const evalCanvas = await captureElement('evaluation-form');
      await yieldToUi();
      if (evalCanvas) {
        const link2 = document.createElement('a');
        link2.href = evalCanvas.toDataURL('image/png');
        link2.download = `استمارة_تقييم_${formData.name.replace(/\s+/g, '_')}.png`;
        link2.click();
      }

      toast.success('تم تحميل الاستمارة بنجاح!', { id: toastId });
    } catch (err) {
      console.error(err);
      toast.error('فشل تحميل الصورة', { id: toastId });
    } finally {
      hideForm();
      setIsCapturing(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  const captureElement = async (id: string): Promise<HTMLCanvasElement | null> => {
    const el = document.getElementById(id);
    if (!el) return null;

    const html2canvas = (await import('html2canvas-pro')).default;
    return html2canvas(el, {
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
      },
    });
  };

  const handleDownloadPdf = async () => {
    setIsCapturing(true);
    await yieldToUi();
    const toastId = toast.loading('جاري تجهيز ملف PDF...');
    try {
      await showFormTemporarily();

      const jsPdfModule = await import('jspdf');
      const jsPDF = jsPdfModule.default;

      const receiptCanvas = await captureElement('receipt');
      if (!receiptCanvas) throw new Error('الاستمارة غير موجودة');
      await yieldToUi();

      const pdf = new jsPDF('p', 'mm', 'a4');
      const pdfWidth = pdf.internal.pageSize.getWidth();

      const receiptHeight = (receiptCanvas.height * pdfWidth) / receiptCanvas.width;
      pdf.addImage(receiptCanvas.toDataURL('image/png'), 'PNG', 0, 0, pdfWidth, receiptHeight);

      const evalCanvas = await captureElement('evaluation-form');
      await yieldToUi();
      if (evalCanvas) {
        const evalHeight = (evalCanvas.height * pdfWidth) / evalCanvas.width;
        pdf.addPage();
        pdf.addImage(evalCanvas.toDataURL('image/png'), 'PNG', 0, 0, pdfWidth, evalHeight);
      }

      pdf.save(`استمارة_${formData.name.replace(/\s+/g, '_')}.pdf`);

      toast.success('تم حفظ ملف PDF بنجاح!', { id: toastId });
    } catch (err) {
      console.error(err);
      toast.error('فشل حفظ PDF', { id: toastId });
    } finally {
      hideForm();
      setIsCapturing(false);
    }
  };

  // -- CLOSED ----------------------------------------------------------
  if (!registrationAllowed && !success) return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-surface" dir="rtl">
      <div className="bg-white rounded-2xl border border-outline-variant/30 p-8 sm:p-12 max-w-md w-full text-center shadow-lg">
        <div className="w-16 h-16 bg-secondary-fixed/30 border border-outline-variant/30 rounded-full flex items-center justify-center mx-auto mb-5 text-primary">
          {capacityFull ? (
            <CalendarX size={28} />
          ) : (
            <ShieldCheck size={28} />
          )}
        </div>
        <h2 className="text-xl font-black text-primary mb-3">
          {capacityFull ? 'آسف.. الطاقة الاستيعابية ممتلئة' : 'التسجيل مغلق حالياً'}
        </h2>
        <p className="text-on-surface-variant text-xs sm:text-sm leading-relaxed mb-8 font-semibold">
          {capacityFull 
            ? 'تم الوصول إلى الحد الأقصى للطاقة الاستيعابية للمسابقة حالياً. سيتم فتح باب التسجيل مرة أخرى في أقرب وقت ممكن.'
            : 'نعتذر إليكم، باب التسجيل مغلق حالياً حسب المواعيد المحددة. يرجى متابعة الإعلانات الرسمية للمواعيد القادمة.'}
        </p>
        <Link href="/" className="inline-flex items-center justify-center gap-2 px-6 py-2.5 w-full rounded-xl bg-primary text-on-primary text-xs font-bold hover:bg-primary-container active:scale-95 transition-all shadow-sm">
          <ArrowLeft size={14} /> العودة للصفحة الرئيسية
        </Link>
      </div>
    </div>
  );

  // -- SUCCESS ----------------------------------------------------------
  if (success) {
    return (
      <>
        {isCapturing && (
          <div className="fixed inset-0 z-[99999] bg-black/50 flex items-center justify-center" style={{ backdropFilter: 'blur(4px)' }}>
            <div className="bg-white rounded-2xl px-8 py-6 shadow-xl text-center max-w-md">
              <div className="w-10 h-10 border-3 border-secondary/25 border-t-primary rounded-full animate-spin mx-auto mb-4" />
              <p className="text-sm font-bold text-on-surface">جاري تجهيز الاستمارة</p>
              <p className="text-xs font-semibold text-on-surface-variant/60 mt-1">يرجى الانتظار قليلاً...</p>
            </div>
          </div>
        )}

        <div className="min-h-screen flex flex-col bg-surface print:hidden" dir="rtl" style={{ fontFamily: 'var(--font-cairo), Cairo, sans-serif' }}>
          <Header />

          <main className="flex-1 flex items-center justify-center p-4 py-12">
            <motion.div
              initial={{ opacity: 0, y: 20, scale: 0.97 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
              className="bg-white rounded-2xl border border-primary/10 p-8 sm:p-10 max-w-md w-full text-center shadow-lg"
            >
              {isWaitlistMode && (
                <div className="bg-amber-50 border border-amber-200 text-amber-800 p-3 rounded-xl mb-5 text-center text-xs font-bold leading-relaxed">
                  <p className="text-xs font-extrabold">تم وضعك في قائمة الانتظار</p>
                  <p className="text-[11px] font-bold text-amber-700 mt-1">لقد اكتمل العدد الأساسي للمسابقة. سنتواصل معك في حال توفر مقعد لك.</p>
                </div>
              )}

              <div className="w-16 h-16 bg-secondary-fixed/30 rounded-full flex items-center justify-center mx-auto mb-5">
                <CheckCircle2 size={36} className="text-secondary" />
              </div>

              <h2 className="text-2xl sm:text-3xl font-black text-primary mb-3">تم التسجيل بنجاح!</h2>
              <p className="text-sm font-bold text-on-surface-variant leading-relaxed mb-6">
                تم تسجيل بياناتك في مسابقة أهل القرآن الكبرى.<br />
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

              <Link
                href="/"
                className="inline-flex items-center gap-1.5 text-xs font-bold text-on-surface-variant hover:text-primary transition-colors"
              >
                <ArrowLeft size={14} />
                العودة للصفحة الرئيسية
              </Link>
            </motion.div>
          </main>

          <Footer />
        </div>

        <div ref={hiddenFormRef} className="hidden print:block">
          <Step4Success
            formData={formData}
            levels={levels}
            getLevelContent={getLevelContent}
            examSlot={examSlot}
            profilePreview={profilePreview}
            studentCode={studentCode}
            isWaitlistMode={isWaitlistMode}
            branchName={branchName}
            memorizationAmount={memorizationAmount}
          />
        </div>
      </>
    );
  }

  // -- FORM --------------------------------------------------------------
  return (
    <div className="min-h-screen flex flex-col bg-surface-container-low" dir="rtl" style={{ fontFamily: 'var(--font-cairo), Cairo, sans-serif' }}>
      <Header />

      {/* ─── Hero Header ─── */}
      <section className="relative min-h-[40vh] md:min-h-[45vh] flex items-center overflow-hidden bg-primary" style={{ clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 30px), 0 100%)' }}>
        <div className="absolute inset-0 islamic-pattern z-0 opacity-[0.5]" />

        <motion.div
          initial={{ opacity: 0, scale: 1.05 }}
          animate={{ opacity: 0.55, scale: 1 }}
          transition={{ duration: 2, ease: 'easeOut' }}
          className="absolute inset-0 z-[1]"
        >
          <div
            className="absolute inset-0 bg-cover bg-center"
            style={{
              backgroundImage: "url('/background.png')",
              backgroundPosition: 'center 40%',
            }}
          />
          <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-transparent to-primary/60" />
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1.5, ease: 'easeOut' }}
          className="absolute -top-32 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-secondary-fixed/8 rounded-full blur-[120px] pointer-events-none z-[2]"
        />

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1.5, ease: 'easeOut', delay: 0.2 }}
          className="absolute -bottom-48 -right-48 w-[600px] h-[600px] bg-secondary-fixed/6 rounded-full blur-[150px] pointer-events-none z-[2]"
        />

        <div className="absolute inset-0 bg-gradient-to-b from-primary/0 via-primary/15 via-50% to-primary/85 to-95% z-[3]" />

        <div className="max-w-7xl mx-auto px-6 relative z-10 text-center w-full py-20">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full bg-primary text-white font-black text-xs mb-5 shadow-md shadow-primary/20"
          >
            <span className="w-1.5 h-1.5 rounded-full bg-secondary-fixed animate-pulse" />
            نموذج التسجيل الإلكتروني
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
            className="text-[32px] sm:text-[44px] md:text-[56px] font-black text-white leading-[1.2] mb-3"
            style={{
              fontFamily: "'Noto Serif', serif",
              textShadow: '0 0 60px rgba(255,224,136,0.3), 0 0 20px rgba(255,224,136,0.2), 0 4px 12px rgba(0,0,0,0.6)',
            }}
          >
            سجل في مسابقة القرآن
          </motion.h1>

          <div className="flex items-center justify-center gap-2 mt-3 mb-6">
            <span className="w-8 h-0.5 rounded-full bg-secondary-fixed/30" />
            <span className="w-2 h-2 rounded-full bg-secondary-fixed/60" />
            <span className="w-8 h-0.5 rounded-full bg-secondary-fixed/30" />
          </div>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.5 }}
            className="text-white text-sm sm:text-base max-w-xl mx-auto leading-relaxed font-semibold"
            style={{ textShadow: '0 2px 8px rgba(0,0,0,0.5)' }}
          >
            أدخل بياناتك الأساسية للاشتراك في مسابقة أهل القرآن الكبرى
          </motion.p>
        </div>

      </section>

      <main className="flex-1 max-w-2xl lg:max-w-5xl w-full mx-auto px-3 sm:px-4 mb-16 md:mb-24 relative z-20">
        
        {/* Stepper */}
        <div className="relative -mt-6 md:-mt-8 mb-5 tour-stepper">
          <div className="flex items-center justify-center gap-0">
            {steps.map((s, i) => (
              <React.Fragment key={s.num}>
                <button
                  type="button"
                  onClick={() => { if (s.num < step) { setStep(s.num); window.scrollTo({ top: 0, behavior: 'smooth' }); } }}
                  className={`flex flex-col items-center gap-1.5 transition-all duration-300 ${s.num <= step ? 'cursor-pointer' : 'cursor-default'}`}
                >
                  <div className={`w-9 h-9 sm:w-9 sm:h-9 rounded-full flex items-center justify-center text-xs sm:text-xs font-black border-2 transition-all duration-300 ${
                    step > s.num
                      ? 'bg-secondary border-secondary text-white shadow-sm'
                    : step === s.num
                      ? 'bg-primary border-primary text-white shadow-md scale-110'
                      : 'bg-white border-primary/15 text-primary/50'
                  }`}>
                    {step > s.num ? <CheckCircle2 size={14} className="sm:size-[14px]" /> : s.num}
                  </div>
                  <span className={`text-xs sm:text-xs font-bold transition-colors duration-300 whitespace-nowrap ${
                    step === s.num ? 'text-primary' : step > s.num ? 'text-primary/70' : 'text-primary/40'
                  }`}>
                    {s.label}
                  </span>
                </button>
                {i < steps.length - 1 && (
                  <div className={`h-0.5 w-8 sm:w-12 mx-1.5 sm:mx-2 mb-6 rounded-full transition-all duration-300 ${
                    step > i + 1 ? 'bg-secondary' : 'bg-primary/10'
                  }`} />
                )}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Card */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.25, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
          className="bg-white rounded-2xl border border-primary/10 mx-auto shadow-lg shadow-primary/8"
        >
          <div className="p-3 sm:p-6 md:p-8">
            <form onSubmit={handleSubmit}>

              {/* Honeypot */}
              <div style={{ display: 'none' }} aria-hidden="true">
                <input
                  type="text"
                  name="website_url_verification"
                  tabIndex={-1}
                  value={honeypot}
                  onChange={e => setHoneypot(e.target.value)}
                  autoComplete="off"
                />
              </div>

              <AnimatePresence mode="wait">
                {/* STEP 1 */}
                {step === 1 && (
                  <motion.div
                    key="step1"
                    initial={{ opacity: 0, x: -30 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 30 }}
                    transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                  >
                    <Step1Personal
                      formData={formData}
                      setFormData={setFormData}
                      fieldErrors={fieldErrors}
                      clearErr={clearErr}
                      isCheckingName={isCheckingName}
                      nameExists={nameExists}
                      isCheckingId={isCheckingId}
                      idExists={idExists}
                      profilePreview={profilePreview}
                      birthCertPreview={birthCertPreview}
                      handleImagePick={handleImagePick}
                    />
                  </motion.div>
                )}

                {/* STEP 2 */}
                {step === 2 && (
                  <motion.div
                    key="step2"
                    initial={{ opacity: 0, x: 30 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -30 }}
                    transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                  >
                    <Step2Level
                      formData={formData}
                      setFormData={setFormData}
                      fieldErrors={fieldErrors}
                      clearErr={clearErr}
                      levels={levels}
                      studentAge={extractedInfo.age}
                      levelCounts={levelCounts}
                      branchName={branchName}
                      setBranchName={setBranchName}
                      memorizationAmount={memorizationAmount}
                      setMemorizationAmount={setMemorizationAmount}
                    />
                  </motion.div>
                )}

                {/* STEP 3 */}
                {step === 3 && (
                  <motion.div
                    key="step3"
                    initial={{ opacity: 0, x: 30 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -30 }}
                    transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                  >
                    <Step3Review
                      formData={formData}
                      setFormData={setFormData}
                      isConfirmed={isConfirmed}
                      setIsConfirmed={setIsConfirmed}
                      setTurnstileToken={setTurnstileToken}
                    />
                  </motion.div>
                )}
              </AnimatePresence>

              {/* Navigation */}
              <div className="mt-6 sm:mt-8 pt-4 sm:pt-5 border-t border-primary/10 flex items-center justify-between gap-3">
                {step > 1 ? (
                  <button 
                    type="button" 
                    onClick={() => { setStep(s => s - 1); window.scrollTo({ top: 0, behavior: 'smooth' }); }} 
                    disabled={loading}
                    className="flex items-center gap-1.5 px-4 sm:px-6 py-3 sm:py-[14px] rounded-xl text-sm font-bold border-2 border-primary/20 text-primary hover:border-primary/40 hover:bg-primary/[0.03] active:scale-95 transition-all disabled:opacity-40"
                  >
                    <ChevronRight size={16} className="sm:size-[18px]" /> السابق
                  </button>
                ) : <div />}
                
                {step < 3 ? (
                  <button 
                    type="button" 
                    onClick={nextStep}
                    className="flex items-center gap-1.5 px-5 sm:px-7 py-3 sm:py-[14px] rounded-xl text-sm font-bold bg-primary text-white hover:bg-primary/90 active:scale-95 transition-all shadow-md shadow-primary/15 tour-next"
                  >
                    التالي <ChevronLeft size={16} className="sm:size-[18px]" />
                  </button>
                ) : (
                  <button 
                    type="submit" 
                    disabled={loading || !isConfirmed}
                    className="flex-1 flex items-center justify-center gap-2 py-3 sm:py-[14px] rounded-xl text-sm font-bold bg-primary text-white hover:bg-primary/90 active:scale-95 transition-all shadow-md shadow-primary/15 disabled:opacity-50 disabled:cursor-not-allowed tour-step4-submit"
                  >
                    {loading ? <div className="w-5 h-5 sm:w-[22px] sm:h-[22px] border-2 border-white/30 border-t-white rounded-full animate-spin" /> : <><Send size={16} className="sm:size-[18px]" /> إرسال طلب التسجيل</>}
                  </button>
                )}
              </div>
            </form>
          </div>
        </motion.div>
      </main>
      <Footer />
    </div>
  );
}
