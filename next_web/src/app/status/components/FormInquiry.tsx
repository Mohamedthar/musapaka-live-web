'use client';

import React, { useState } from 'react';
import { CreditCard, Search, Phone, FileText } from 'lucide-react';
import Step5Success from '@/app/register/components/Step5Success';
import Field from '@/app/register/components/Field';
import type { CompetitionLevel } from '@/lib/database.types';

export default function FormInquiry() {
  const [nationalId, setNationalId] = useState('');
  const [phone, setPhone] = useState('');
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [studentData, setStudentData] = useState<any>(null);
  const [levels, setLevels] = useState<CompetitionLevel[]>([]);

  const handleInquiry = async (e: React.FormEvent) => {
    e.preventDefault();
    if (nationalId.length !== 14) {
      setError('الرقم القومي يجب أن يتكون من 14 رقماً');
      return;
    }
    if (!phone || !/^(010|011|012|015)\d{8}$/.test(phone)) {
      setError('رقم الهاتف المصري غير صحيح');
      return;
    }

    setError('');
    setLoading(true);
    setSearched(true);
    setStudentData(null);

    try {
      const response = await fetch('/api/inquiry', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ nationalId, phone }),
      });

      const data = await response.json();

      if (!response.ok) {
        setError(data.error || 'حدث خطأ أثناء الاستعلام');
        return;
      }

      setStudentData(data.student);
      setLevels(data.levels);
    } catch (err) {
      console.error('Fetch error:', err);
      setError('فشل الاتصال بالخادم. يرجى المحاولة مرة أخرى.');
    } finally {
      setLoading(false);
    }
  };

  const handleNewSearch = () => {
    setStudentData(null);
    setSearched(false);
    setError('');
    setNationalId('');
    setPhone('');
  };

  // Render registration success screen if student is found
  if (studentData) {
    const formData = {
      name: studentData.name,
      phone: studentData.phone,
      nationalId: studentData.national_id,
      age: studentData.age.toString(),
      gender: studentData.gender,
      memorizerName: studentData.memorizer_name || '',
      memorizerPhone: studentData.memorizer_phone || '',
      memorizerAddress: studentData.memorizer_address || '',
      location: studentData.location || '',
      level: studentData.level,
      selectedRewaya: studentData.selected_rewaya || '',
    };

    const getLevelContent = () => {
      const found = levels.find(l => l.title === studentData.level);
      return found ? found.content : '';
    };

    const examSlot = studentData.exam_date && studentData.exam_hour !== null ? (() => {
      try {
        const date = new Date(studentData.exam_date);
        const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'السبت', 'الجمعة'];
        const dayName = days[date.getDay()];
        const dateOnly = studentData.exam_date.split('T')[0];

        let h = studentData.exam_hour;
        let timeStr = `${h}:00`;
        if (h === 0) timeStr = '12 منتصف الليل';
        else if (h < 12) timeStr = `${h} صباحاً`;
        else if (h === 12) timeStr = '12 ظهراً';
        else timeStr = `${h - 12} مساءً`;

        return `${dayName} - ${dateOnly} (الساعة ${timeStr})`;
      } catch {
        return '';
      }
    })() : '';

    const profilePreview = studentData.profile_image_url || null;
    const studentCode = studentData.student_code || '';
    const isWaitlistMode = !studentData.exam_date || studentData.exam_hour === null;
    const branchName = studentData.branch_name || '';
    const memorizationAmount = studentData.memorization_amount ?? null;

    return (
      <div className="animate-fade-in">
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
          onNewSearch={handleNewSearch}
        />
      </div>
    );
  }

  return (
    <div className="w-full animate-fade-in">
      <div className="text-center mb-8">
        <div className="inline-flex items-center justify-center w-12 h-12 bg-[var(--bg-section)] text-[var(--text-primary)] rounded-2xl mb-4 border border-[var(--border)] shadow-sm">
          <FileText size={24} />
        </div>
        <h2 className="text-xl font-black text-[var(--text-primary)] mb-2">استعلام الاستمارة وموعد الاختبار</h2>
        <p className="text-slate-500 text-xs sm:text-sm font-semibold max-w-sm mx-auto leading-relaxed">
          أدخل الرقم القومي ورقم الهاتف المستخدمين أثناء التسجيل لعرض استمارة الاشتراك وموعد الاختبار الخاص بك.
        </p>
      </div>

      <form onSubmit={handleInquiry} className="space-y-5 max-w-md mx-auto">
        
        <Field
          label="الرقم القومي للمتسابق"
          icon={<CreditCard size={17} />}
          value={nationalId}
          onChange={v => { setNationalId(v); setError(''); setSearched(false); }}
          placeholder="أدخل الـ 14 رقماً للمتسابق"
          type="number"
          required
          error={searched && nationalId.length !== 14 ? 'الرقم القومي يجب أن يتكون من 14 رقماً' : undefined}
        />

        <Field
          label="رقم هاتف الطالب / ولي الأمر"
          icon={<Phone size={17} />}
          value={phone}
          onChange={v => { setPhone(v); setError(''); setSearched(false); }}
          placeholder="مثال: 01012345678"
          type="tel"
          required
          error={searched && phone && !/^(010|011|012|015)\d{8}$/.test(phone) ? 'رقم الهاتف المصري غير صحيح' : undefined}
        />

        {error && <p className="text-red-500 text-xs font-bold text-center mt-2">{error}</p>}

        <button
          type="submit"
          disabled={loading || nationalId.length !== 14 || !phone}
          className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-bold bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed mt-2"
        >
          {loading ? (
            <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <>
              <span>عرض الاستمارة</span>
              <Search size={16} />
            </>
          )}
        </button>
      </form>
    </div>
  );
}
