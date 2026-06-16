'use client';
/* Deployment trigger: 2026-05-19T23:36:27Z */
import React, { useState, useEffect, useMemo, useRef } from 'react';
import { CheckCircle2, ChevronLeft, ChevronRight, ShieldCheck, ArrowLeft, Send, CalendarX, Download, Printer, FileText, X, AlertTriangle } from 'lucide-react';
import { toast } from 'react-hot-toast';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import type { CompetitionLevel } from '@/lib/database.types';

const isFacebookBrowser = typeof navigator !== 'undefined' && (
  /FBAN|FBAV|Instagram|FB_IAB/i.test(navigator.userAgent) ||
  (typeof document !== 'undefined' && /l\.facebook\.com|lm\.facebook\.com|m\.facebook\.com/.test(document.referrer))
);

// Subcomponents
import Step1Personal from './components/Step1Personal';
import Step2Level from './components/Step3Level';
import Step3Review from './components/Step4Review';
import Step4Success from './components/Step5Success';


interface RegisterClientProps {
  initialAllowed: boolean;
  initialCapacityFull: boolean;
  registrationStartDate: string | null;
}

export default function RegisterClient({ initialAllowed, initialCapacityFull, registrationStartDate }: RegisterClientProps) {
  const searchParams = useSearchParams();
  const [loading, setLoading] = useState(false);
  const [levels, setLevels] = useState<CompetitionLevel[]>([]);
  const [success, setSuccess] = useState(false);
  const [isConfirmed, setIsConfirmed] = useState(false);
  const [registrationAllowed, setRegistrationAllowed] = useState(initialAllowed);
  const [capacityFull, setCapacityFull] = useState(initialCapacityFull);

  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({ name: '', phone: '', nationalId: '', birthDate: '', memorizerName: '', memorizerPhone: '', memorizerAddress: '', location: '', gender: '', level: '', selectedRewaya: '' });
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
  const [cloudProfileUrl, setCloudProfileUrl] = useState<string | null>(null);
  const [cloudBirthCertUrl, setCloudBirthCertUrl] = useState<string | null>(null);
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
  const [showNotesModal, setShowNotesModal] = useState(false);
  const turnstileWidgetIdRef = useRef<string | null>(null);
  const cachedUploads = useRef<{ profileUrl?: string; birthCertUrl?: string }>({});
  const clearErr = (key: string) => setFieldErrors(p => { if (!p[key]) return p; const n = { ...p }; delete n[key]; return n; });

  const formattedStartDate = useMemo(() => {
    if (!registrationStartDate) return null;
    try {
      const d = new Date(registrationStartDate);
      if (isNaN(d.getTime())) return null;
      return new Intl.DateTimeFormat('ar-EG', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      }).format(d);
    } catch {
      return null;
    }
  }, [registrationStartDate]);

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
      try {
        const res = await fetch('/api/check-duplicate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name: formData.name.trim() }),
        });
        const d = await res.json();
        setNameExists(!!d.name_exists);
      } catch {
        setNameExists(false);
      }
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
      try {
        const res = await fetch('/api/check-duplicate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ national_id: formData.nationalId.trim() }),
        });
        const d = await res.json();
        setIdExists(!!d.national_id_exists);
      } catch {
        setIdExists(false);
      }
      setIsCheckingId(false);
    }, 500);

    return () => clearTimeout(handler);
  }, [formData.nationalId]);

  useEffect(() => {
    const load = async () => {
      const countsMap: Record<string, number> = {};

      const saved = typeof window !== 'undefined' ? localStorage.getItem('musapaka_registration_draft') : null;
      if (saved) {
        try {
          const draft = JSON.parse(saved);
          const safe: Partial<typeof formData> = {};
          if (draft.name) safe.name = draft.name;
          if (draft.birthDate) safe.birthDate = draft.birthDate;
          if (draft.memorizerName) safe.memorizerName = draft.memorizerName;
          if (draft.memorizerPhone) safe.memorizerPhone = draft.memorizerPhone;
          if (draft.memorizerAddress) safe.memorizerAddress = draft.memorizerAddress;
          if (draft.location) safe.location = draft.location;
          setFormData(p => ({ ...p, ...safe }));
          if (draft.branchName) setBranchName(draft.branchName);
          if (draft.memorizationAmount !== undefined) setMemorizationAmount(draft.memorizationAmount);
          if (draft.gender) setFormData((p: typeof formData) => ({ ...p, gender: draft.gender }));
          if (draft.level) setFormData((p: typeof formData) => ({ ...p, level: draft.level }));
          if (draft.selectedRewaya) setFormData((p: typeof formData) => ({ ...p, selectedRewaya: draft.selectedRewaya }));
        } catch (_) {}

        // استعادة روابط الصور المرفوعة سابقاً (لمنع إعادة الرفع)
        const savedUrls = localStorage.getItem('musapaka_uploaded_urls');
        if (savedUrls) {
          try {
            const urls = JSON.parse(savedUrls);
            if (urls.profileUrl) cachedUploads.current.profileUrl = urls.profileUrl;
            if (urls.birthCertUrl) cachedUploads.current.birthCertUrl = urls.birthCertUrl;
          } catch (_) {}
        }
      }

      try {
        const [settingsRes, levelsRes] = await Promise.all([
          fetch('/api/settings'),
          fetch('/api/levels'),
        ]);

        const settingsJson = await settingsRes.json();
        const levelsJson = await levelsRes.json();

        if (settingsJson.settings) {
          const data = settingsJson.settings;
          const status = settingsJson.status;

          const totalStud = status?.total_students ?? 0;
          const totalSlots = status?.total_slots ?? 0;
          const filledSlots = status?.filled_slots ?? 0;

          if (status) {
            // في وضع التطوير، تجاهل حالة التسجيل من الخادم وافتح التسجيل دايماً
            if (process.env.NODE_ENV === 'development') {
              setRegistrationAllowed(true);
              setCapacityFull(false);
            } else {
            const hasSlots = status.has_available_slots === true;
            const isOpen = status.is_registration_open === true;

            if (!isOpen) {
              setRegistrationAllowed(false);
              setCapacityFull(false);
            } else if (!hasSlots) {
              setRegistrationAllowed(false);
              setCapacityFull(true);
            } else {
              setRegistrationAllowed(true);
              setCapacityFull(false);
            }
            }
          }

          if (settingsJson.level_counts) {
            setLevelCounts(settingsJson.level_counts);
          }
        }

        if (levelsJson.levels?.length) {
          setLevels(levelsJson.levels);
          const preselected = searchParams.get('level');
          if (preselected && levelsJson.levels.some((l: { title: string }) => l.title === preselected)) {
            setFormData(p => ({ ...p, level: preselected }));
          } else {
            setFormData(p => ({ ...p, level: '', selectedRewaya: '' }));
          }
        }
      } catch (err) {
        console.error("Error loading data:", err);
      }
    };
    load();
  }, [searchParams]);

  useEffect(() => {
    if (step >= 3) return;
    if (typeof window === 'undefined') return;
    try {
      const draft: Record<string, unknown> = {
        name: formData.name,
        memorizerName: formData.memorizerName,
        memorizerPhone: formData.memorizerPhone,
        memorizerAddress: formData.memorizerAddress,
        location: formData.location,
        branchName,
        memorizationAmount,
        gender: formData.gender,
        level: formData.level,
        selectedRewaya: formData.selectedRewaya,
      };
      // Only save birthDate if it's a complete YYYY-MM-DD (not intermediate state)
      if (/^\d{4}-\d{2}-\d{2}$/.test(formData.birthDate)) {
        draft.birthDate = formData.birthDate;
      }
      localStorage.setItem('musapaka_registration_draft', JSON.stringify(draft));
      // حفظ روابط الصور المرفوعة لمنع إعادة الرفع
      if (cachedUploads.current.profileUrl || cachedUploads.current.birthCertUrl) {
        localStorage.setItem('musapaka_uploaded_urls', JSON.stringify(cachedUploads.current));
      }
    } catch (_) {}
  }, [formData, branchName, memorizationAmount, step]);

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

  useEffect(() => {
    return () => {
      if (profilePreview) URL.revokeObjectURL(profilePreview);
      if (birthCertPreview) URL.revokeObjectURL(birthCertPreview);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleImagePick = (e: React.ChangeEvent<HTMLInputElement>, type: 'profile' | 'birthCert') => {
    const file = e.target.files?.[0]; if (!file) return;

    const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'];
    if (!ALLOWED_TYPES.includes(file.type)) {
      toast.error('صيغة الملف غير مدعومة. الصيغ المدعومة: JPEG, PNG, WebP, HEIC');
      e.target.value = '';
      return;
    }

    const MAX_FILE_SIZE = 10 * 1024 * 1024;
    if (file.size > MAX_FILE_SIZE) {
      toast.error('حجم الملف كبير جداً — الحد الأقصى 10 ميجابايت');
      e.target.value = '';
      return;
    }

    const url = URL.createObjectURL(file);
    if (type === 'profile') {
      if (profilePreview) URL.revokeObjectURL(profilePreview);
      setProfileImage(file); setProfilePreview(url); clearErr('profile');
    } else {
      if (birthCertPreview) URL.revokeObjectURL(birthCertPreview);
      setBirthCertImage(file); setBirthCertPreview(url); clearErr('birthCert');
    }
    e.target.value = '';
  };

  const compressImage = async (file: File): Promise<Blob> => {
    return new Promise((resolve, reject) => {
      const objectUrl = URL.createObjectURL(file);
      const img = new Image();
      const timeout = setTimeout(() => {
        URL.revokeObjectURL(objectUrl);
        reject(new Error('استغرق ضغط الصورة وقتاً طويلاً جداً'));
      }, 20000);

      img.onload = () => {
        clearTimeout(timeout);
        URL.revokeObjectURL(objectUrl);
        const canvas = document.createElement('canvas');
        const MAX_WIDTH = 1200;
        const MAX_HEIGHT = 1200;
        let width = img.width;
        let height = img.height;

        if (width === 0 || height === 0) {
          reject(new Error('أبعاد الصورة غير صالحة'));
          return;
        }

        if (width > height) {
          if (width > MAX_WIDTH) { height *= MAX_WIDTH / width; width = MAX_WIDTH; }
        } else {
          if (height > MAX_HEIGHT) { width *= MAX_HEIGHT / height; height = MAX_HEIGHT; }
        }

        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        if (!ctx) { reject(new Error('فشل معالجة الصورة')); return; }
        ctx.drawImage(img, 0, 0, width, height);
        canvas.toBlob(
          (blob) => {
            canvas.width = 0; canvas.height = 0;
            if (blob) resolve(blob);
            else reject(new Error('فشل ضغط الصورة'));
          },
          'image/jpeg',
          0.7
        );
      };

      img.onerror = () => {
        clearTimeout(timeout);
        URL.revokeObjectURL(objectUrl);
        reject(new Error('صيغة الصورة غير مدعومة من المتصفح — يرجى استخدام JPEG أو PNG'));
      };

      img.src = objectUrl;
    });
  };

  const uploadToCloudinary = async (fileOrBlob: File | Blob) => {
    const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;
    const uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET;

    // Direct Cloudinary upload (single attempt — no retry to avoid duplicates)
    if (cloudName && uploadPreset) {
      const fd = new FormData();
      fd.append('file', fileOrBlob);
      fd.append('upload_preset', uploadPreset);
      const r = await fetch(
        `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
        { method: 'POST', body: fd, signal: AbortSignal.timeout(30000) }
      );
      const res = await r.json();
      if (!r.ok) throw new Error(res.error?.message || 'فشل في رفع الصورة');
      return res.secure_url as string;
    }

    // Fallback: via server (single attempt — no retry to avoid duplicate uploads)
    const fd = new FormData();
    fd.append('file', fileOrBlob);
    const r = await fetch('/api/upload', {
      method: 'POST',
      body: fd,
      signal: AbortSignal.timeout(30000),
    });
    const res = await r.json();
    if (!r.ok) throw new Error(res.error || 'فشل في رفع الصورة');
    return res.url as string;
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
      if (!formData.birthDate) errs.birthDate = 'تاريخ الميلاد مطلوب';
      else if (formData.birthDate !== extractedInfo.birthDate) errs.birthDate = 'تاريخ الميلاد او الرقم القومي غير صحيحين';
      if (!formData.gender || (extractedInfo.isMale !== null && formData.gender !== (extractedInfo.isMale ? 'ذكر' : 'أنثى'))) {
        errs.gender = 'النوع غير صحيح';
      }
      if (!birthCertImage) errs.birthCert = 'شهادة الميلاد مطلوبة';
      if (nameExists) errs.name = 'هذا الاسم مسجل مسبقاً في النظام';
      if (idExists) errs.nationalId = 'هذا الرقم القومي مسجل مسبقاً';
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

    // تجديد رمز Turnstile قبل الإرسال إذا كان منتهياً
    let finalToken = turnstileToken;
    const widgetId = turnstileWidgetIdRef.current;
    const ts = typeof window !== 'undefined' ? (window as unknown as { turnstile?: { reset: (id: string) => void; getResponse: (id: string) => string | undefined } }).turnstile : undefined;
    if (widgetId && ts) {
      // نجرب ناخد التوكين الحالي الأول بدون reset
      const currentResponse = ts.getResponse(widgetId);
      if (currentResponse) {
        finalToken = currentResponse;
      } else {
        // التوكين منتهي، نعمل reset ونستنى توكين جديد
        ts.reset(widgetId);
        for (let i = 0; i < 25; i++) {
          await new Promise(r => setTimeout(r, 200));
          const t = ts.getResponse(widgetId);
          if (t) { finalToken = t; setTurnstileToken(t); break; }
        }
      }
    }

    if (!finalToken) {
      return toast.error('يرجى الضغط على مربع التحقق الأمني (أنا لست روبوت)');
    }

    if (!formData.memorizerName.trim()) return toast.error('اسم المحفظ مطلوب');
    if (!formData.memorizerPhone.trim()) return toast.error('رقم هاتف المحفظ مطلوب');
    else if (!/^(010|011|012|015)\d{8}$/.test(formData.memorizerPhone.trim())) return toast.error('رقم هاتف المحفظ غير صحيح');

    if (formData.phone.trim() && formData.phone.trim() === formData.memorizerPhone.trim()) {
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
      let profileUrl: string | null = cachedUploads.current.profileUrl ?? null;
      let birthUrl: string | null = cachedUploads.current.birthCertUrl ?? null;

      if (!profileUrl || !birthUrl) {
        // أول محاولة: ضغط ورفع الصور
        const [profileBlob, birthBlob] = await Promise.all([
          profileImage ? compressImage(profileImage) : Promise.resolve(null),
          birthCertImage ? compressImage(birthCertImage) : Promise.resolve(null),
        ]);

        const saveCache = () => {
          try { localStorage.setItem('musapaka_uploaded_urls', JSON.stringify(cachedUploads.current)); } catch (_) {}
        };

        if (!birthUrl) {
          if (!birthBlob) throw new Error('فشل تجهيز شهادة الميلاد');
          toast.loading('جاري رفع شهادة الميلاد...', { id: uploadToast });
          birthUrl = await uploadToCloudinary(birthBlob);
          cachedUploads.current.birthCertUrl = birthUrl;
          saveCache();
        }

        if (!profileUrl) {
          if (!profileBlob) throw new Error('فشل تجهيز الصورة الشخصية');
          toast.loading('جاري رفع الصورة الشخصية...', { id: uploadToast });
          profileUrl = await uploadToCloudinary(profileBlob);
          cachedUploads.current.profileUrl = profileUrl;
          saveCache();
        }
      }

      if (!birthUrl || !profileUrl) {
        throw new Error('فشل رفع الصور — يرجى المحاولة مرة أخرى');
      }

      toast.loading('جاري إرسال بيانات التسجيل...', { id: uploadToast });

      const res = await fetch('/api/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          token: finalToken,
          website_url_verification: honeypot,
          name: formData.name.trim(),
          phone: formData.phone.trim(),
          national_id: formData.nationalId.trim(),
          level: formData.level,
          age: (() => {
            if (!formData.birthDate) return null;
            const [y, m, d] = formData.birthDate.split('-').map(Number);
            const bd = new Date(y, m - 1, d);
            const now = new Date();
            let a = now.getFullYear() - bd.getFullYear();
            if (now.getMonth() < bd.getMonth() || (now.getMonth() === bd.getMonth() && now.getDate() < bd.getDate())) a--;
            return a;
          })(),
          birth_date: formData.birthDate,
          gender: formData.gender,
          profile_image_url: profileUrl,
          birth_certificate_url: birthUrl,
          memorizer_name: formData.memorizerName.trim(),
          memorizer_phone: formData.memorizerPhone.trim(),
          memorizer_address: formData.memorizerAddress.trim(),
          location: formData.location.trim(),
          selected_rewaya: formData.selectedRewaya || null,
          branch_name: branchName.trim() || null,
          memorization_amount: memorizationAmount,
        }),
        signal: AbortSignal.timeout(30000),
      });

      const result = await res.json();
      toast.dismiss(uploadToast);

      if (!res.ok) {
        throw new Error(result.error || 'فشل التسجيل');
      }

      setStudentCode(result.data.student_code);
      setExamDate(result.data.exam_date);
      setExamHour(result.data.exam_hour);
      setCloudProfileUrl(result.data.profile_image_url || null);
      setCloudBirthCertUrl(result.data.birth_certificate_url || null);

      cachedUploads.current = {};
      localStorage.removeItem('musapaka_uploaded_urls');

      localStorage.setItem('last_reg_time', Date.now().toString());
      localStorage.removeItem('musapaka_registration_draft');
      toast.success('تم التسجيل بنجاح!');
      setSuccess(true);
      setShowNotesModal(true);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } catch (err: unknown) {
      toast.dismiss(uploadToast);
      if (err instanceof DOMException && err.name === 'TimeoutError') {
        toast.error('انتهت مهلة الاتصال بالخادم - لم تفقد بياناتك، حاول مرة أخرى');
      } else if (err instanceof TypeError && (err.message.includes('fetch') || err.message.includes('network') || err.message.includes('Network'))) {
        toast.error('فشل الاتصال بالخادم - تحقق من اتصالك بالإنترنت وحاول مرة أخرى');
      } else {
        const msg = err instanceof Error ? err.message : 'حدث خطأ غير متوقع';
        if (msg.includes('مسبقاً') || msg.includes('موجود')) {
          toast.error(msg);
        } else if (msg.includes('فشل رفع') || msg.includes('فشل في رفع')) {
          toast.error('فشل رفع الصور - لم تفقد بياناتك، حاول مرة أخرى');
        } else {
          toast.error(msg);
        }
      }
    } finally {
      setLoading(false);
    }
  };

  // -- CAPTURE / DOWNLOAD HANDLERS -------------------------------------
  const captureElement = async (id: string): Promise<HTMLCanvasElement | null> => {
    const el = document.getElementById(id);
    if (!el) return null;

    const parent = el.closest('.hidden.print\\:block') as HTMLElement | null;
    const wasHidden = parent ? parent.classList.contains('hidden') : false;

    const originalDisplay = el.style.display;
    const originalVisibility = el.style.visibility;
    const originalMaxHeight = el.style.maxHeight;
    const originalOverflow = el.style.overflow;

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
      el.style.maxHeight = originalMaxHeight;
      el.style.overflow = originalOverflow;

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
    const toastId = toast.loading('جاري تجهيز استمارة البيانات...');
    try {
      const receiptCanvas = await captureElement('receipt');
      if (!receiptCanvas) throw new Error('الاستمارة غير موجودة');

      toast.loading('جاري تحميل استمارة البيانات...', { id: toastId });
      const dataUrl = receiptCanvas.toDataURL('image/jpeg', 0.85);
      const link = document.createElement('a');
      link.href = dataUrl;
      link.download = `استمارة_${formData.name.replace(/\s+/g, '_')}.jpg`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      const evalCanvas = await captureElement('evaluation-form');
      if (evalCanvas) {
        await new Promise(r => setTimeout(r, 500));
        const dataUrl2 = evalCanvas.toDataURL('image/jpeg', 0.85);
        const link2 = document.createElement('a');
        link2.href = dataUrl2;
        link2.download = `استمارة_تقييم_${formData.name.replace(/\s+/g, '_')}.jpg`;
        document.body.appendChild(link2);
        link2.click();
        document.body.removeChild(link2);
      }

      toast.success('تم تحميل الملف', { id: toastId, duration: 4000 });
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
    const toastId = toast.loading('جاري تجهيز استمارة البيانات...');
    try {
      const jsPdfModule = await import('jspdf');
      const jsPDF = jsPdfModule.default;

      const receiptCanvas = await captureElement('receipt');
      if (!receiptCanvas) throw new Error('الاستمارة غير موجودة');

      toast.loading('جاري إنشاء ملف PDF...', { id: toastId });

      const pdf = new jsPDF('p', 'mm', 'a4');
      const pdfWidth = pdf.internal.pageSize.getWidth();
      const pdfHeight = pdf.internal.pageSize.getHeight();

      const receiptHeight = (receiptCanvas.height * pdfWidth) / receiptCanvas.width;
      const receiptData = receiptCanvas.toDataURL('image/jpeg', 0.92);
      pdf.addImage(receiptData, 'JPEG', 0, 0, pdfWidth, Math.min(receiptHeight, pdfHeight));

      const evalCanvas = await captureElement('evaluation-form');
      if (evalCanvas) {
        const evalHeight = (evalCanvas.height * pdfWidth) / evalCanvas.width;
        const evalData = evalCanvas.toDataURL('image/jpeg', 0.92);
        pdf.addPage();
        pdf.addImage(evalData, 'JPEG', 0, 0, pdfWidth, Math.min(evalHeight, pdfHeight));
      }

      const pdfFilename = `استمارة_${formData.name.replace(/\s+/g, '_')}.pdf`;
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
      toast.error('فشل حفظ PDF — حاول مرة أخرى', { id: toastId });
    } finally {
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
          {capacityFull ? 'اكتمال المواعيد' : 'التسجيل مغلق'}
        </h2>
        <p className="text-on-surface-variant text-xs sm:text-sm leading-relaxed mb-8 font-semibold">
          {capacityFull 
            ? 'نعتذر، جميع مواعيد الاختبارات المتاحة حالياً مكتملة بالكامل. سيتم فتح التسجيل فور إضافة مواعيد جديدة من قبل إدارة المسابقة.'
            : formattedStartDate
              ? `التسجيل مغلق حالياً. سيتم فتح باب التسجيل يوم ${formattedStartDate} إن شاء الله.`
              : 'التسجيل مغلق حالياً. سيتم فتح باب التسجيل في الموعد الرسمي المُعلن عنه في ورقة الإعلان عن المسابقة. يرجى متابعة الإعلانات الرسمية.'}
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
              
              <div className="w-16 h-16 bg-secondary-fixed/30 rounded-full flex items-center justify-center mx-auto mb-5">
                <CheckCircle2 size={36} className="text-secondary" />
              </div>

              <h2 className="text-2xl sm:text-3xl font-black text-primary mb-3">تم التسجيل بنجاح!</h2>
              <p className="text-sm font-bold text-on-surface-variant leading-relaxed mb-6">
                تم تسجيل بياناتك في مسابقة أهل القرآن الكبرى.
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

        {/* ── NOTES MODAL ── */}
        <AnimatePresence>
          {showNotesModal && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/60 print:hidden"
              style={{ backdropFilter: 'blur(4px)' }}
              onClick={() => setShowNotesModal(false)}
              dir="rtl"
            >
              <motion.div
                initial={{ opacity: 0, scale: 0.9, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.9, y: 20 }}
                transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                onClick={(e) => e.stopPropagation()}
                className="bg-white rounded-2xl shadow-2xl max-w-lg w-full max-h-[85vh] overflow-y-auto"
                style={{ fontFamily: 'var(--font-cairo), Cairo, sans-serif' }}
              >
                {/* Header */}
                <div className="sticky top-0 bg-white z-10 flex items-center justify-between p-5 border-b border-slate-100">
                  <div className="flex items-center gap-2.5">
                    <div className="w-9 h-9 bg-secondary-fixed/30 rounded-full flex items-center justify-center">
                      <AlertTriangle size={18} className="text-secondary" />
                    </div>
                    <h3 className="text-lg font-black text-primary">ملاحظات هامة</h3>
                  </div>
                  <button
                    onClick={() => setShowNotesModal(false)}
                    className="w-9 h-9 rounded-full bg-slate-100 hover:bg-slate-200 flex items-center justify-center transition-colors cursor-pointer"
                  >
                    <X size={18} className="text-slate-600" />
                  </button>
                </div>

                {/* Printing warning */}
                <div className="p-5">
                  <div className="p-4 border-2 border-secondary/30 rounded-xl bg-secondary-fixed/10">
                    <div className="flex items-start gap-2.5">
                      <Printer size={18} className="text-secondary flex-shrink-0 mt-0.5" />
                      <div>
                        <p className="text-sm font-black text-secondary mb-1">يجب طباعة الاستمارة وإحضارها</p>
                        <p className="text-xs font-bold text-on-surface-variant leading-relaxed">
                          يجب طباعة الاستمارة في ورقة واحدة أو تنزيلها كملف PDF وطباعتها، وإحضارها معك في موعد الاختبار المحدد داخل الاستمارة. لا يسمح بدخول الاختبار بدون الاستمارة المطبوعة.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Close button */}
                <div className="px-5 pb-5">
                  <button
                    onClick={() => setShowNotesModal(false)}
                    className="w-full py-3 rounded-xl bg-primary text-white text-sm font-bold hover:bg-primary/85 active:scale-[0.98] transition-all cursor-pointer"
                  >
                    حسناً، فهمت
                  </button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="hidden print:block">
          <Step4Success
            formData={formData}
            levels={levels}
            getLevelContent={getLevelContent}
            examSlot={examSlot}
            profilePreview={cloudProfileUrl || profilePreview}
            studentCode={studentCode}
            branchName={branchName}
            memorizationAmount={memorizationAmount}
          />
        </div>
      </>
    );
  }

  // -- FACEBOOK INTERSTITIAL --------------------------------------------
  if (isFacebookBrowser) {
    const currentUrl = typeof window !== 'undefined' ? window.location.href : '';
    const isIOS = /iPhone|iPad|iPod/i.test(navigator.userAgent);

    return (
      <div className="min-h-screen bg-surface flex items-center justify-center p-4" dir="rtl" style={{ fontFamily: 'var(--font-cairo), Cairo, sans-serif' }}>
        <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full text-center border border-amber-200">
          <div className="w-20 h-20 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <AlertTriangle size={40} className="text-amber-600" />
          </div>

          <h2 className="text-xl font-black text-primary mb-4">يرجى فتح الرابط في متصفح خارجي</h2>
          <p className="text-sm font-bold text-on-surface-variant leading-relaxed mb-6">
            متصفح فيسبوك المدمج لا يدعم تحميل وطباعة الاستمارات. لضمان تجربة كاملة، يرجى فتح الرابط في {isIOS ? 'Safari' : 'Google Chrome'}.
          </p>

          <div className="space-y-3">
            {!isIOS && (
              <button
                onClick={() => {
                  const url = currentUrl.replace(/^https?:\/\//, '');
                  window.location.href = `intent://${url}#Intent;scheme=https;package=com.android.chrome;end`;
                }}
                className="w-full py-3.5 rounded-xl bg-primary text-white text-sm font-black hover:bg-primary/90 active:scale-[0.98] transition-all shadow-md cursor-pointer flex items-center justify-center gap-2"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2"/><path d="M12 8v8M8 12h8" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/></svg>
                فتح في Google Chrome
              </button>
            )}

            <button
              onClick={() => {
                navigator.clipboard.writeText(currentUrl).then(() => {
                  toast.success('تم نسخ الرابط! الصقه في ' + (isIOS ? 'Safari' : 'Chrome'));
                }).catch(() => {});
              }}
              className="w-full py-3 rounded-xl border-2 border-slate-200 text-slate-700 text-sm font-black hover:bg-slate-50 active:scale-[0.98] transition-all cursor-pointer"
            >
              نسخ الرابط
            </button>

            {isIOS && (
              <button
                onClick={() => window.open(currentUrl, '_blank')}
                className="w-full py-3 rounded-xl border-2 border-amber-300 text-amber-700 text-sm font-black hover:bg-amber-50 active:scale-[0.98] transition-all cursor-pointer"
              >
                فتح في Safari
              </button>
            )}
          </div>

          <p className="text-xs font-bold text-on-surface-variant/50 mt-6">
            {isIOS
              ? 'أو اضغط على أيقونة Safari في شريط أدوات فيسبوك السفلي'
              : 'أو اضغط على ⋮ في الأعلى واختر "فتح في Chrome"'}
          </p>
        </div>
      </div>
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
          {/* Progress Bar */}
          <div className="max-w-md mx-auto mb-4 px-2">
            <div className="w-full h-1.5 bg-primary/10 rounded-full overflow-hidden">
              <motion.div
                className="h-full bg-primary rounded-full"
                initial={{ width: `${((step - 1) / steps.length) * 100}%` }}
                animate={{ width: `${(step / steps.length) * 100}%` }}
                transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
              />
            </div>
            <p className="text-center text-[10px] font-bold text-primary/50 mt-1">
              الخطوة {step} من {steps.length}
            </p>
          </div>
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
                      : 'bg-white border-primary/15 text-primary/60'
                  }`}>
                    {step > s.num ? <CheckCircle2 size={14} className="sm:size-[14px]" /> : s.num}
                  </div>
                  <span className={`text-xs sm:text-xs font-bold transition-colors duration-300 whitespace-nowrap ${
                    step === s.num ? 'text-primary' : step > s.num ? 'text-primary/70' : 'text-primary/60'
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
                      onTurnstileWidgetLoad={(id) => { turnstileWidgetIdRef.current = id; }}
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
