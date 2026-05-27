'use client';

import React, { useState } from 'react';
import { CreditCard, Search, ShieldCheck, ArrowRight } from 'lucide-react';
import Step5Success from '@/app/register/components/Step5Success';
import type { CompetitionLevel } from '@/lib/database.types';

export default function FormInquiry() {
  const [nationalId, setNationalId] = useState('');
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [studentData, setStudentData] = useState<any>(null);
  const [levels, setLevels] = useState<CompetitionLevel[]>([]);

  const idValid = nationalId.length === 14;
  const canSubmit = idValid && !loading;

  const handleInquiry = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idValid) { setError('الرقم القومي يجب أن يتكون من 14 رقماً'); return; }

    setError('');
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
      if (!response.ok) { setError(data.error || 'حدث خطأ أثناء الاستعلام'); return; }
      setStudentData(data.student);
      setLevels(data.levels);
    } catch {
      setError('فشل الاتصال بالخادم. يرجى المحاولة مرة أخرى.');
    } finally {
      setLoading(false);
    }
  };

  const handleNewSearch = () => {
    setStudentData(null); setSearched(false); setError('');
    setNationalId('');
  };

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
      <div className="animate-fade-in -mx-4 -mt-8 sm:-mt-14">
        <Step5Success
          formData={formData} levels={levels} getLevelContent={getLevelContent}
          examSlot={examSlot} profilePreview={studentData.profile_image_url || null}
          studentCode={studentData.student_code || ''}
          isWaitlistMode={!studentData.exam_date || studentData.exam_hour === null}
          branchName={studentData.branch_name || ''}
          memorizationAmount={studentData.memorization_amount ?? null}
          onNewSearch={handleNewSearch}
        />
      </div>
    );
  }

  return (
    <div className="w-full">
      {/* Header */}
      <div className="text-center mb-8">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-secondary/10 mb-4">
          <ShieldCheck size={28} className="text-secondary" />
        </div>
        <h1 className="text-xl sm:text-3xl font-black text-primary mb-2">استعلام الاستمارة وموعد الاختبار</h1>
        <p className="text-sm text-on-surface-variant max-w-md mx-auto leading-relaxed">
          أدخل الرقم القومي لعرض استمارة القبول
        </p>
      </div>

      {/* Form Card */}
      <form onSubmit={handleInquiry} className="max-w-md mx-auto">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 sm:p-8 space-y-5 sm:space-y-6">
          {/* National ID */}
          <div>
            <label className="block text-sm font-bold text-gray-700 mb-2">الرقم القومي للمتسابق <span className="text-red-400">*</span></label>
            <div className="relative">
              <input
                type="text" inputMode="numeric" maxLength={14}
                value={nationalId}
                onChange={e => { setNationalId(e.target.value.replace(/\D/g, '')); setSearched(false); setError(''); }}
                placeholder="أدخل الـ 14 رقماً"
                className={`w-full bg-gray-50 border-2 rounded-2xl py-3.5 pr-12 pl-4 text-sm font-semibold transition-all duration-200 outline-none
                  ${searched && !idValid ? 'border-red-200 bg-red-50/30' : 'border-gray-100 focus:border-secondary focus:bg-white focus:ring-4 focus:ring-secondary/5'}
                  text-gray-900 placeholder:text-gray-400`}
              />
              <CreditCard size={18} className={`absolute right-4 top-1/2 -translate-y-1/2 transition-colors ${searched && !idValid ? 'text-red-400' : 'text-gray-400'}`} />
            </div>
            {searched && !idValid && <p className="text-red-500 text-xs font-bold mt-1.5 pr-1">الرقم القومي يجب أن يتكون من 14 رقماً</p>}
          </div>

          {/* Error */}
          {error && (
            <div className="bg-red-50 border border-red-100 rounded-2xl px-5 py-3.5">
              <p className="text-red-600 text-xs font-bold text-center">{error}</p>
            </div>
          )}

          {/* Submit */}
          <button
            type="submit" disabled={!canSubmit}
            className="w-full flex items-center justify-center gap-2 sm:gap-2.5 py-3.5 sm:py-4 rounded-2xl font-bold text-white transition-all duration-300
              bg-gradient-to-r from-secondary to-secondary-fixed-dim hover:from-secondary-fixed-dim hover:to-secondary
              shadow-lg shadow-secondary/20 hover:shadow-xl hover:shadow-secondary/30 hover:-translate-y-0.5
              disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:translate-y-0 disabled:hover:shadow-lg"
          >
            {loading ? (
              <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <span>عرض الاستمارة</span>
                <ArrowRight size={18} />
              </>
            )}
          </button>
        </div>
      </form>

      {/* Footer hint */}
      <p className="text-center text-xs text-gray-400 mt-6">
        في حالة وجود أي استفسار، يرجى التواصل مع إدارة المسابقة
      </p>
    </div>
  );
}
