/* eslint-disable @next/next/no-img-element */
'use client';
// Deployment trigger: 2026-05-19T23:36:27Z
import React, { useState, useEffect, useMemo } from 'react';
import { supabase } from '@/lib/supabase';
import { CheckCircle2, ChevronLeft, ChevronRight, HelpCircle, ShieldCheck, ArrowLeft, Send, CalendarX, BookOpen } from 'lucide-react';
import { toast } from 'react-hot-toast';
import Link from 'next/link';
import Header from '@/components/Header';
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
        // Fetch exact student count
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
          // Calculate total capacity
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
            setIsWaitlistMode(false); // Disable waitlist mode completely
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
          const firstAvailable = lvls.find(l => {
            const c = countsMap[l.title] || 0;
            return l.max_capacity === null || c < l.max_capacity;
          });
          const initialLevel = firstAvailable || lvls[0];
          const defaultRewaya = initialLevel?.has_rewaya && initialLevel.available_rewayas?.length ? initialLevel.available_rewayas[0] : '';
          setFormData(p => ({ ...p, level: initialLevel.title, selectedRewaya: defaultRewaya }));
        }
      } catch (err) {
        console.error("Error loading levels:", err);
      }

      // Start tour after loading is done and DOM is ready
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
        if (l.min_age && studentAge < l.min_age) return false;
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

  // --- Image Compression Helper ---
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
            0.7 // Quality
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
      throw new Error('??? ??????? ??? ?????. ???? ??????? ?? ???????.');
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
        throw new Error(res.error?.message || '??? ??? ??????');
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
      if (!formData.name.trim()) errs.name = '???? ?????';
      else if (formData.name.trim().split(/\s+/).length < 4) errs.name = '????? ???? ???? - ??? ?? ????? ?? 4 ?????';
      if (!formData.phone.trim()) errs.phone = '???? ??? ??????';
      else if (!/^(010|011|012|015)\d{8}$/.test(formData.phone.trim())) errs.phone = '??? ?????? ??? ????';
      if (!formData.location.trim()) errs.location = '???? ???????';
      if (!profileImage) errs.profile = '?????? ??????? ??????';
      setFieldErrors(errs);
      if (Object.keys(errs).length) return toast.error(Object.values(errs)[0]);
      setStep(2); window.scrollTo({ top: 0, behavior: 'smooth' });
    } else if (step === 2) {
      if (!extractedInfo.isValid) errs.nationalId = '????? ?????? ??? ????';
      if (parseInt(formData.age) !== extractedInfo.age) errs.age = '????? ??? ????';
      if (extractedInfo.isValid) {
        const idGender = extractedInfo.isMale ? '???' : '????';
        if (formData.gender !== idGender) errs.gender = '????? ??????? ??? ????';
      }
      if (!birthCertImage) errs.birthCert = '???? ????? ??????? ?? ??????';
      setFieldErrors(errs);
      if (Object.keys(errs).length) return toast.error(Object.values(errs)[0]);
      setStep(3); window.scrollTo({ top: 0, behavior: 'smooth' });
    } else if (step === 3) {
      if (!formData.level) errs.level = '???? ???????';
      const selLevel = levels.find(l => l.title === formData.level);
      if (selLevel?.has_rewaya && selLevel.available_rewayas?.length && !formData.selectedRewaya) {
        errs.rewaya = '???? ??????? ?? ???????';
        toast.error('???? ?????? ??????? ?? ???????');
      }
      // Validate branch / custom amount
      if (selLevel?.branches && selLevel.branches.length > 0 && !branchName) {
        errs.branch = '??? ?????? ?????? / ?????';
        toast.error('???? ?????? ?????? ?? ?????');
      }
      if (selLevel?.require_custom_amount && memorizationAmount == null) {
        errs.branch = '??? ?????? ???? ?????';
        toast.error('???? ?????? ??? ??????? ????????');
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
      const days = ['?????', '???????', '????????', '????????', '??????', '??????', '?????'];
      const dayName = days[date.getDay()];
      const dateOnly = examDate.split('T')[0];

      let timeStr = `${examHour}:00`;
      const h = Number(examHour);
      if (!isNaN(h)) {
        if (h === 0) timeStr = '12 ????? ?????';
        else if (h < 12) timeStr = `${h} ??????`;
        else if (h === 12) timeStr = '12 ?????';
        else timeStr = `${h - 12} ?????`;
      }

      return `??? ${dayName} ??????? ${dateOnly} - ?????? ${timeStr}`;
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
      return toast.error('???? ???????? ?????? ??? ?????? ??????? ??? ????');
    }

    if (!turnstileToken && process.env.NEXT_PUBLIC_TURNSTILE_SKIP_VERIFICATION !== 'true') {
      return toast.error('???? ????? ?????? ?? ?????? (Turnstile)');
    }

    if (!formData.memorizerName.trim()) return toast.error('??? ???????? ?????');

    if (formData.phone.trim() && formData.memorizerPhone.trim() && formData.phone.trim() === formData.memorizerPhone.trim()) {
      return toast.error('??? ???? ?????? ??? ?? ???? ??????? ?? ??? ???? ??????');
    }

    // Check level max_capacity before uploading or compressing
    const selLevel = levels.find(l => l.title === formData.level);
    if (selLevel && selLevel.max_capacity != null) {
      const count = levelCounts[selLevel.title] || 0;
      if (count >= selLevel.max_capacity) {
        return toast.error('?????? ??? ??????? ????? ?????? ????? ?????? ??????????.');
      }
    }

    setLoading(true);
    const uploadToast = toast.loading('???? ?????? ????? ?????????...');

    try {
      // 1. Parallel Compression
      const [profileBlob, birthBlob] = await Promise.all([
        profileImage ? compressImage(profileImage) : Promise.resolve(null),
        birthCertImage ? compressImage(birthCertImage) : Promise.resolve(null),
      ]);

      // 2. Parallel Uploads
      const [profileUrl, birthUrl] = await Promise.all([
        profileBlob ? uploadToCloudinary(profileBlob) : Promise.resolve(null),
        birthBlob ? uploadToCloudinary(birthBlob) : Promise.resolve(null),
      ]);

      // 3. Single API Request
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
        throw new Error(result.error || '??? ???????');
      }

      setStudentCode(result.data.student_code);
      setExamDate(result.data.exam_date);
      setExamHour(result.data.exam_hour);

      localStorage.setItem('last_reg_time', Date.now().toString());
      toast.success('?? ??????? ?????!');
      setSuccess(true);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } catch (err: unknown) {
      toast.dismiss(uploadToast);
      console.error('Registration error:', err);
      toast.error(err instanceof Error ? err.message : '??? ??? ????? ???????');
    } finally {
      setLoading(false);
    }
  };

  // -- CLOSED ----------------------------------------------------------
  if (!registrationAllowed && !success) return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-white" dir="rtl">
      <div className="card-elevated p-8 sm:p-12 max-w-md w-full text-center">
        <div className="w-16 h-16 bg-[var(--beige-light)] border border-[var(--border)] rounded-full flex items-center justify-center mx-auto mb-5 text-[var(--primary)]">
          {capacityFull ? (
            <CalendarX size={28} />
          ) : (
            <ShieldCheck size={28} />
          )}
        </div>
        <h2 className="text-xl font-black text-[var(--primary)] mb-3">
          {capacityFull ? '?????.. ?????? ??????? ???????' : '??? ??????? ???? ??????'}
        </h2>
        <p className="text-[var(--text-secondary)] text-xs sm:text-sm leading-relaxed mb-8 font-semibold">
          {capacityFull 
            ? '??? ?????? ???? ??????? ?????? ???????? ??????? ?????? ??????????. ?????? ??????? ?????? ??????? ?? ?? ????? ??????.'
            : '???? ????????? ??? ??????? ???? ?????? ????? ?? ????? ????????. ???? ?????? ???????? ??????? ????????.'}
        </p>
        <Link href="/" className="inline-flex items-center justify-center gap-2 px-6 py-2.5 w-full rounded-xl btn-primary text-xs font-bold shadow-sm">
          <ArrowLeft size={14} /> ?????? ?????? ????????
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
  const steps = [{ num: 1, label: '???????? ???????' }, { num: 2, label: '??????? ???????' }, { num: 3, label: '????? ?????' }, { num: 4, label: '?????? ??????' }];

  return (
    <div className="min-h-screen bg-white" dir="rtl" style={{ fontFamily: 'var(--font-cairo), Cairo, sans-serif' }}>
      {/* Header */}
      <Header />

      <main className="max-w-2xl mx-auto px-4 py-12 sm:py-16 tour-start">
        
        {/* Joyride Tour */}
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
            title="???? ??????? ????????"
            className="flex items-center justify-center w-11 h-11 rounded-full bg-[var(--primary)] text-white shadow-md hover:scale-105 active:scale-95 transition-all duration-300 border border-[var(--border)] group relative"
          >
            <HelpCircle size={18} className="text-[var(--beige)]" />
            <span className="absolute left-12 bg-[var(--primary)] text-white text-[10px] font-bold px-3 py-1.5 rounded-lg opacity-0 -translate-x-2 pointer-events-none group-hover:opacity-100 group-hover:translate-x-0 transition-all whitespace-nowrap shadow-sm border border-white/10">
              ?????? ???????
            </span>
          </button>
        </div>

        {/* Stepper */}
        <div className="mb-8 tour-stepper flex flex-col items-center">
          <div className="flex items-center justify-center gap-0 w-full">
            {steps.map((s, i) => (
              <React.Fragment key={s.num}>
                <div className="flex flex-col items-center gap-2">
                  <div className={`w-9 h-9 rounded-full flex items-center justify-center text-xs font-black border transition-all duration-200 ${step > s.num ? 'bg-[var(--primary)] border-[var(--primary)] text-white' : step === s.num ? 'bg-[var(--primary)] border-[var(--primary)] text-white shadow-sm scale-105' : 'bg-white border-[var(--border)] text-[var(--text-muted)]'}`}>
                    {step > s.num ? <CheckCircle2 size={16} className="text-[var(--beige)]" /> : s.num}
                  </div>
                  <span className={`text-[10px] sm:text-xs font-bold transition-colors ${step >= s.num ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'}`}>{s.label}</span>
                </div>
                {i < steps.length - 1 && (
                  <div className={`h-0.5 w-8 sm:w-16 mx-1 sm:mx-2 mb-6 rounded-full transition-all duration-300 ${step > s.num ? 'bg-[var(--primary)]' : 'bg-[var(--border)]'}`} />
                )}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Form Title Card (Clean Navy) */}
        <div className="bg-[var(--primary)] text-white rounded-2xl p-5 mb-6 border border-white/10 flex items-center gap-4 shadow-sm">
          <div className="w-10 h-10 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center text-[var(--beige)]">
            <BookOpen size={18} />
          </div>
          <div>
            <h1 className="text-base font-extrabold text-white">????? ????? ??????????</h1>
            <p className="text-[10px] text-white/70 font-semibold">???? ????? ???? ???????? ???? ????? ????? ???????? ????? ???????.</p>
          </div>
        </div>

        {/* Card with delicate border */}
        <div className="card-elevated overflow-hidden mx-auto">
          <div className="p-6 sm:p-8">
            <form onSubmit={handleSubmit}>

              {/* Honeypot field - Hidden from users */}
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

              {/* STEP 1 */}
              {step === 1 && (
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
              )}

              {/* STEP 2 */}
              {step === 2 && (
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
              )}

              {/* STEP 3 */}
              {step === 3 && (
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
              )}

              {/* STEP 4 */}
              {step === 4 && (
                <Step4Review
                  formData={formData}
                  setFormData={setFormData}
                  isConfirmed={isConfirmed}
                  setIsConfirmed={setIsConfirmed}
                  setTurnstileToken={setTurnstileToken}
                />
              )}

              {/* Navigation Buttons */}
              <div className="mt-8 pt-6 border-t border-[var(--border)] flex items-center justify-between gap-3">
                {step > 1 ? (
                  <button 
                    type="button" 
                    onClick={() => { setStep(s => s - 1); window.scrollTo({ top: 0, behavior: 'smooth' }); }} 
                    disabled={loading}
                    className="flex items-center gap-1.5 px-4.5 py-2.5 rounded-xl text-xs font-bold border-2 border-[var(--border)] text-[var(--text-primary)] hover:border-[var(--beige)] hover:bg-[var(--beige-light)] transition-all font-bold rounded-xl text-xs px-4.5 py-2.5 text-[var(--primary)] border border-[var(--border)] transition-all disabled:opacity-50"
                  >
                    <ChevronRight size={14} /> ??????
                  </button>
                ) : <div />}
                
                {step < 4 ? (
                  <button 
                    type="button" 
                    onClick={nextStep}
                    className="flex items-center gap-1.5 px-6 py-2.5 rounded-xl text-xs font-bold btn-primary tour-next"
                  >
                    ?????? <ChevronLeft size={14} />
                  </button>
                ) : (
                  <button 
                    type="submit" 
                    disabled={loading || !isConfirmed}
                    className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl text-xs font-bold btn-primary transition-all disabled:opacity-50 disabled:cursor-not-allowed tour-step4-submit"
                  >
                    {loading ? <div className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" /> : <><Send size={14} /> ????? ?????? ?????????</>}
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>
      </main>
      <style jsx global>{`
        @media print {
          @page { size: A4; margin: 0; }
          body { font-family: var(--font-cairo), Cairo, sans-serif !important; background: white !important; margin: 0 !important; padding: 0 !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
          nav, button, footer, .print\\:hidden { display: none !important; }
        }
      `}</style>
    </div>
  );
}
