/* eslint-disable @next/next/no-img-element */
'use client';
// Deployment trigger: 2026-05-19T23:36:27Z
import React, { useState, useEffect, useMemo } from 'react';
import { supabase } from '@/lib/supabase';
import { CheckCircle2, ChevronLeft, ChevronRight, HelpCircle, ShieldCheck, ArrowLeft, Send, CalendarX, BookOpen } from 'lucide-react';
import { toast } from 'react-hot-toast';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import type { CompetitionLevel } from '@/lib/database.types';

// Subcomponents
import TourGuide from './components/TourGuide';
import Step1Personal from './components/Step1Personal';
import Step2Official from './components/Step2Official';
import Step3Level from './components/Step3Level';
import Step4Review from './components/Step4Review';
import Step5Success from './components/Step5Success';

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

  const [runTour, setRunTour] = useState(false);
  const [tourKey, setTourKey] = useState(0);
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({ name: '', phone: '', nationalId: '', age: '', memorizerName: '', memorizerPhone: '', memorizerAddress: '', location: '', gender: '???', level: '', selectedRewaya: '' });
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
  const [levelSearch, setLevelSearch] = useState('');
  const [levelDropdownOpen, setLevelDropdownOpen] = useState(false);
  const [turnstileToken, setTurnstileToken] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [levelCounts, setLevelCounts] = useState<Record<string, number>>({});
  const clearErr = (key: string) => setFieldErrors(p => { if (!p[key]) return p; const n = { ...p }; delete n[key]; return n; });

  const steps = [
    { num: 1, label: 'البيانات الشخصية' },
    { num: 2, label: 'المستندات الرسمية' },
    { num: 3, label: 'مستوى المسابقة' },
    { num: 4, label: 'مراجعة البيانات' },
  ];

  useEffect(() => {
    const handler = setTimeout(async () => {
      if (formData.name.trim().length < 3) {
        setNameExists(false);
        return;
      }
      setIsCheckingName(true);
      const { data } = await supabase
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
      const { data } = await supabase
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
        const { count: studentCount, error: countErr } = await supabase
          .from('students')
          .select('*', { count: 'exact', head: true });

        if (countErr) {
          console.error("Error fetching student count:", countErr);
        }
        const count = studentCount ?? 0;

        const { data } = await supabase
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
        const { data: stdLevels } = await supabase.from('students').select('level');
        stdLevels?.forEach(s => {
          countsMap[s.level] = (countsMap[s.level] || 0) + 1;
        });
        setLevelCounts(countsMap);
      } catch (err) {
        console.error("Error loading level counts:", err);
      }

      try {
        const { data: lvls } = await supabase.from('competition_levels').select('*').eq('is_active', true).order('level_code');
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

      if (typeof window !== 'undefined' && !localStorage.getItem('musapaka_tour_done')) {
        localStorage.setItem('musapaka_tour_done', 'true');
        setTimeout(() => setRunTour(true), 550);
      }
    };
    load();
  }, []);

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

  const filteredLevels = useMemo(() => {
    const studentAge = extractedInfo.age;
    let filtered = levels;
    if (studentAge !== null) {
      filtered = levels.filter(l => {
        if (l.min_age && studentAge <= l.min_age) return false;
        if (l.max_age && studentAge > l.max_age) return false;
        return true;
      });
    }
    const q = levelSearch.trim().toLowerCase();
    if (!q) return filtered;
    return filtered.filter(l => l.content.toLowerCase().includes(q) || l.title.toLowerCase().includes(q));
  }, [levels, extractedInfo.age, levelSearch]);

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
      setFieldErrors(errs);
      if (Object.keys(errs).length) return toast.error(Object.values(errs)[0]);
      setStep(2); window.scrollTo({ top: 0, behavior: 'smooth' });
    } else if (step === 2) {
      if (!extractedInfo.isValid) errs.nationalId = 'الرقم القومي غير صحيح';
      if (parseInt(formData.age) !== extractedInfo.age) errs.age = 'العمر غير صحيح';
      if (extractedInfo.isValid) {
        const idGender = extractedInfo.isMale ? 'ذكر' : 'أنثى';
        if (formData.gender !== idGender) errs.gender = 'النوع غير متطابق';
      }
      if (!birthCertImage) errs.birthCert = 'شهادة الميلاد مطلوبة';
      setFieldErrors(errs);
      if (Object.keys(errs).length) return toast.error(Object.values(errs)[0]);
      setStep(3); window.scrollTo({ top: 0, behavior: 'smooth' });
    } else if (step === 3) {
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
      setStep(4); window.scrollTo({ top: 0, behavior: 'smooth' });
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
      const [profileBlob, birthBlob] = await Promise.all([
        profileImage ? compressImage(profileImage) : Promise.resolve(null),
        birthCertImage ? compressImage(birthCertImage) : Promise.resolve(null),
      ]);

      const [profileUrl, birthUrl] = await Promise.all([
        profileBlob ? uploadToCloudinary(profileBlob) : Promise.resolve(null),
        birthBlob ? uploadToCloudinary(birthBlob) : Promise.resolve(null),
      ]);

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
      <Step5Success
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
    );
  }

  // -- FORM --------------------------------------------------------------
  return (
    <div className="min-h-screen flex flex-col bg-surface-container-low" dir="rtl" style={{ fontFamily: 'var(--font-cairo), Cairo, sans-serif' }}>
      <Header />

      {/* ─── Hero Header ─── */}
      <section className="relative bg-gradient-to-br from-primary via-[#0a2f1f] to-primary-container pt-16 pb-20 md:pt-20 md:pb-24 px-4 overflow-hidden">
        {/* Glow lights */}
        <div className="absolute -top-20 -right-20 w-[300px] md:w-[500px] h-[300px] md:h-[500px] bg-secondary-fixed/6 rounded-full blur-[100px] z-0" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] md:w-[800px] h-[400px] md:h-[600px] bg-secondary-fixed/8 rounded-full blur-[130px] z-0" />
        <div className="absolute -bottom-10 -left-20 w-[250px] md:w-[400px] h-[250px] md:h-[400px] bg-secondary-fixed/4 rounded-full blur-[90px] z-0" />

        {/* Islamic geometric decoration */}
        <div className="absolute inset-0 z-[1] opacity-[0.12]">
          {/* Diamond shapes */}
          <svg className="absolute top-8 right-8 w-32 h-32 md:w-48 md:h-48" viewBox="0 0 200 200" fill="none">
            <polygon points="100,10 190,100 100,190 10,100" stroke="#ffe088" strokeWidth="1.2" />
            <polygon points="100,35 165,100 100,165 35,100" stroke="#ffe088" strokeWidth="0.8" />
            <polygon points="100,60 140,100 100,140 60,100" stroke="#ffe088" strokeWidth="0.5" />
            <circle cx="100" cy="100" r="3" fill="#ffe088" />
          </svg>
          <svg className="absolute bottom-8 left-8 w-32 h-32 md:w-48 md:h-48" viewBox="0 0 200 200" fill="none">
            <polygon points="100,10 190,100 100,190 10,100" stroke="#ffe088" strokeWidth="1.2" />
            <polygon points="100,35 165,100 100,165 35,100" stroke="#ffe088" strokeWidth="0.8" />
            <polygon points="100,60 140,100 100,140 60,100" stroke="#ffe088" strokeWidth="0.5" />
            <circle cx="100" cy="100" r="3" fill="#ffe088" />
          </svg>

          {/* Star / Octagram */}
          <svg className="absolute top-1/2 right-6 -translate-y-1/2 w-28 h-28 md:w-40 md:h-40" viewBox="0 0 200 200" fill="none">
            <polygon points="100,10 125,75 190,100 125,125 100,190 75,125 10,100 75,75" stroke="#ffe088" strokeWidth="1" />
            <polygon points="100,40 115,85 160,100 115,115 100,160 85,115 40,100 85,85" stroke="#ffe088" strokeWidth="0.6" />
            <circle cx="100" cy="100" r="4" fill="#ffe088" />
          </svg>

          {/* Connecting lines */}
          <svg className="absolute top-0 left-1/2 -translate-x-1/2 w-20 h-full opacity-50" viewBox="0 0 40 300" fill="none" preserveAspectRatio="none">
            <line x1="20" y1="0" x2="20" y2="300" stroke="#ffe088" strokeWidth="0.4" />
            <circle cx="20" cy="40" r="2" fill="#ffe088" />
            <circle cx="20" cy="150" r="2" fill="#ffe088" />
            <circle cx="20" cy="260" r="2" fill="#ffe088" />
          </svg>
        </div>

        <div className="relative z-10 max-w-2xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="inline-flex items-center gap-1.5 bg-white/10 backdrop-blur-sm text-secondary-fixed text-[10px] font-black px-3 py-1.5 rounded-full mb-5 border border-white/5"
          >
            <BookOpen size={11} />
            <span>نموذج التسجيل الإلكتروني</span>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.08 }}
            className="text-3xl sm:text-4xl md:text-5xl font-black text-secondary-fixed mb-5"
            style={{ fontFamily: "'Noto Serif', serif" }}
          >
            سجل في مسابقة القرآن
          </motion.h1>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.14 }}
            className="w-16 h-1 bg-secondary-fixed/40 mx-auto rounded-full mb-5"
          />

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="text-white/55 text-xs sm:text-sm leading-relaxed font-semibold max-w-lg mx-auto"
          >
            أدخل بياناتك الأساسية للاشتراك في مسابقة أهل القرآن الكبرى
          </motion.p>
        </div>
      </section>

      <main className="flex-1 max-w-2xl w-full mx-auto px-3 md:px-4 -mt-6 md:-mt-8 mb-16 md:mb-24 relative z-20 tour-start">
        
        <TourGuide
          tourKey={tourKey}
          runTour={runTour}
          setRunTour={setRunTour}
          step={step}
        />

        {/* Floating Help Button */}
        <div className="fixed bottom-6 left-6 z-50 print:hidden">
          <button 
            type="button" 
            onClick={() => {
              setTourKey(prev => prev + 1);
              setRunTour(true);
            }}
            title="عرض دليل التسجيل"
            className="flex items-center justify-center w-11 h-11 rounded-full bg-primary text-white shadow-md hover:scale-105 active:scale-95 transition-all duration-300 border border-outline-variant/30 group relative"
          >
            <HelpCircle size={18} className="text-secondary-fixed" />
            <span className="absolute left-12 bg-primary text-white text-[10px] font-bold px-3 py-1.5 rounded-lg opacity-0 -translate-x-2 pointer-events-none group-hover:opacity-100 group-hover:translate-x-0 transition-all whitespace-nowrap shadow-sm border border-white/10">
              شرح التسجيل
            </span>
          </button>
        </div>

        {/* Stepper */}
        <div className="mb-5 tour-stepper">
          <div className="flex items-center justify-center gap-0">
            {steps.map((s, i) => (
              <React.Fragment key={s.num}>
                <button
                  type="button"
                  onClick={() => { if (s.num < step) { setStep(s.num); window.scrollTo({ top: 0, behavior: 'smooth' }); } }}
                  className={`flex flex-col items-center gap-1.5 transition-all duration-300 ${s.num <= step ? 'cursor-pointer' : 'cursor-default'}`}
                >
                  <div className={`w-9 h-9 rounded-full flex items-center justify-center text-xs font-black border-2 transition-all duration-300 ${
                    step > s.num
                      ? 'bg-secondary border-secondary text-on-secondary shadow-sm'
                      : step === s.num
                        ? 'bg-primary border-primary text-white shadow-md scale-110'
                        : 'bg-white border-outline-variant text-on-surface-variant'
                  }`}>
                    {step > s.num ? <CheckCircle2 size={14} /> : s.num}
                  </div>
                  <span className={`text-[10px] sm:text-xs font-bold transition-colors duration-300 whitespace-nowrap ${
                    step === s.num ? 'text-primary' : step > s.num ? 'text-on-surface' : 'text-on-surface-variant/70'
                  }`}>
                    {s.label}
                  </span>
                </button>
                {i < steps.length - 1 && (
                  <div className={`h-0.5 w-6 sm:w-12 mx-1 sm:mx-2 mb-5 rounded-full transition-all duration-300 ${
                    step > i + 1 ? 'bg-secondary' : 'bg-outline-variant/30'
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
          className="bg-white rounded-2xl border border-outline-variant/20 mx-auto shadow-lg shadow-black/3"
        >
          <div className="p-4 md:p-8">
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
                      profilePreview={profilePreview}
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
                    <Step2Official
                      formData={formData}
                      setFormData={setFormData}
                      fieldErrors={fieldErrors}
                      clearErr={clearErr}
                      isCheckingId={isCheckingId}
                      idExists={idExists}
                      birthCertPreview={birthCertPreview}
                      handleImagePick={handleImagePick}
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
                    <Step3Level
                      formData={formData}
                      setFormData={setFormData}
                      fieldErrors={fieldErrors}
                      clearErr={clearErr}
                      levels={levels}
                      filteredLevels={filteredLevels}
                      levelSearch={levelSearch}
                      setLevelSearch={setLevelSearch}
                      levelDropdownOpen={levelDropdownOpen}
                      setLevelDropdownOpen={setLevelDropdownOpen}
                      levelCounts={levelCounts}
                      branchName={branchName}
                      setBranchName={setBranchName}
                      memorizationAmount={memorizationAmount}
                      setMemorizationAmount={setMemorizationAmount}
                    />
                  </motion.div>
                )}

                {/* STEP 4 */}
                {step === 4 && (
                  <motion.div
                    key="step4"
                    initial={{ opacity: 0, x: 30 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -30 }}
                    transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                  >
                    <Step4Review
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
              <div className="mt-8 pt-5 border-t border-outline-variant/20 flex items-center justify-between gap-3">
                {step > 1 ? (
                  <button 
                    type="button" 
                    onClick={() => { setStep(s => s - 1); window.scrollTo({ top: 0, behavior: 'smooth' }); }} 
                    disabled={loading}
                    className="flex items-center gap-1.5 px-5 py-3 rounded-xl text-sm font-bold border-2 border-outline-variant/40 text-on-surface hover:border-secondary hover:bg-secondary-fixed/10 active:scale-95 transition-all disabled:opacity-40"
                  >
                    <ChevronRight size={16} /> السابق
                  </button>
                ) : <div />}
                
                {step < 4 ? (
                  <button 
                    type="button" 
                    onClick={nextStep}
                    className="flex items-center gap-1.5 px-6 py-3 rounded-xl text-sm font-bold bg-primary text-on-primary hover:bg-primary-container active:scale-95 transition-all shadow-md shadow-primary/15 tour-next"
                  >
                    التالي <ChevronLeft size={16} />
                  </button>
                ) : (
                  <button 
                    type="submit" 
                    disabled={loading || !isConfirmed}
                    className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-bold bg-primary text-on-primary hover:bg-primary-container active:scale-95 transition-all shadow-md shadow-primary/15 disabled:opacity-50 disabled:cursor-not-allowed tour-step4-submit"
                  >
                    {loading ? <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : <><Send size={16} /> إرسال طلب التسجيل</>}
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
