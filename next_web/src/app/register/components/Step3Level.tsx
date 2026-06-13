import React, { useMemo } from 'react';
import { ChevronDown } from 'lucide-react';
import { toast } from 'react-hot-toast';
import type { CompetitionLevel, RegistrationFormData } from '@/lib/database.types';

interface Step3LevelProps {
  formData: {
    level: string;
    selectedRewaya: string;
  };
  setFormData: React.Dispatch<React.SetStateAction<RegistrationFormData>>;
  fieldErrors: Record<string, string>;
  clearErr: (key: string) => void;
  levels: CompetitionLevel[];
  studentAge: number | null;
  levelCounts: Record<string, number>;
  branchName: string;
  setBranchName: (name: string) => void;
  memorizationAmount: number | null;
  setMemorizationAmount: (val: number | null) => void;
}

export default function Step3Level({
  formData,
  setFormData,
  fieldErrors,
  clearErr,
  levels,
  studentAge,
  levelCounts,
  branchName,
  setBranchName,
  memorizationAmount,
  setMemorizationAmount
}: Step3LevelProps) {
  const filteredLevels = useMemo(() => {
    if (studentAge === null) return levels;
    return levels.filter(l => {
      const op = l.age_op || l.birth_year_op;
      // gt: أكبر من (فقط) — السن > min_age
      if (op === 'gt' && l.min_age != null && studentAge <= l.min_age) return false;
      // gte: أكبر من أو يساوي — السن >= min_age
      if (op === 'gte' && l.min_age != null && studentAge < l.min_age) return false;
      // lt: أقل من — السن < max_age
      if (op === 'lt' && l.max_age != null && studentAge >= l.max_age) return false;
      // lte: أقل من أو يساوي — السن <= max_age
      if (op === 'lte' && l.max_age != null && studentAge > l.max_age) return false;
      // range: بين min_age و max_age (شامل)
      if (op === 'range') {
        if (l.min_age != null && studentAge < l.min_age) return false;
        if (l.max_age != null && studentAge > l.max_age) return false;
        return true;
      }
      // fallback: بدون age_op — تعامل شامل (>= min_age, <= max_age)
      if (l.min_age != null && studentAge < l.min_age) return false;
      if (l.max_age != null && studentAge > l.max_age) return false;
      return true;
    });
  }, [levels, studentAge]);

  const activeLevels = filteredLevels.filter(l => l.is_active !== false);
  const inactiveLevels = filteredLevels.filter(l => l.is_active === false);

  return (
    <div className="space-y-5">
      <div className="mb-2">
        <h2 className="text-lg sm:text-xl font-black text-primary">اختيار المستوى</h2>
        <p className="text-primary/60 text-sm mt-0.5">حدد الفرع المناسب لك</p>
      </div>

      {/* Level Select - native dropdown */}
      <div className="rounded-2xl bg-primary/[0.02] p-3 sm:p-4 md:p-6">
        <label htmlFor="level-select" className="block text-sm font-bold text-primary mb-1.5">
          مستوى المسابقة <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <select
            id="level-select"
            value={formData.level}
            onChange={e => {
              const selLevel = levels.find(l => l.title === e.target.value);
              if (selLevel) {
                const isFull = selLevel.max_capacity != null && (levelCounts[selLevel.title] || 0) >= selLevel.max_capacity;
                if (isFull) {
                  toast.error('هذا المستوى ممتلئ تماماً');
                  return;
                }
              }
              const defaultRewaya = selLevel?.has_rewaya && selLevel?.available_rewayas?.length ? selLevel.available_rewayas[0] : '';
              setFormData((p) => ({ ...p, level: e.target.value, selectedRewaya: defaultRewaya }));
              setBranchName('');
              setMemorizationAmount(null);
              clearErr('level');
            }}
            className={`w-full bg-white border-2 ${fieldErrors.level ? 'border-amber-400' : 'border-primary/20'} rounded-xl py-[14px] px-3 sm:px-4 text-primary text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all appearance-none shadow-sm`}
          >
            <option value="" disabled>-- اختر مستوى المسابقة --</option>
            {activeLevels.length > 0 && (
              <optgroup label="━━ المستويات المتاحة ━━">
                {activeLevels.map(l => {
                  const count = levelCounts[l.title] || 0;
                  const isFull = l.max_capacity != null && count >= l.max_capacity;
                  const ageLabel = [];
                  const op = l.age_op || l.birth_year_op;
                  if (op === 'gt' && l.min_age) ageLabel.push(`السن > ${l.min_age}`);
                  else if (op === 'gte' && l.min_age) ageLabel.push(`السن ≥ ${l.min_age}`);
                  else if (op === 'lt' && l.max_age) ageLabel.push(`السن < ${l.max_age}`);
                  else if (op === 'lte' && l.max_age) ageLabel.push(`السن ≤ ${l.max_age}`);
                  else if (op === 'range' && l.min_age && l.max_age) ageLabel.push(`${l.min_age}-${l.max_age} سنة`);
                  else {
                    if (l.min_age) ageLabel.push(`فوق ${l.min_age} عام`);
                    if (l.max_age) ageLabel.push(`${l.max_age} عام فأقل`);
                  }
                  const extra = [
                    ageLabel.length ? ageLabel.join(' ') : '',
                    isFull ? 'ممتلئ' : l.max_capacity ? `${count}/${l.max_capacity}` : '',
                  ].filter(Boolean).join(' · ');
                  return (
                    <option key={l.title} value={l.title} disabled={isFull}>
                      {l.content} — {l.title}{extra ? `  (${extra})` : ''}
                    </option>
                  );
                })}
              </optgroup>
            )}
            {inactiveLevels.length > 0 && (
              <optgroup label="━━ قريباً ━━">
                {inactiveLevels.map(l => (
                  <option key={l.title} value={l.title} disabled>
                    {l.content} — {l.title}
                  </option>
                ))}
              </optgroup>
            )}
          </select>
          <ChevronDown size={14} className="sm:size-[16px] absolute left-2 sm:left-3 top-1/2 -translate-y-1/2 text-primary/30 pointer-events-none" />
        </div>
        {filteredLevels.length === 0 && studentAge !== null && (
          <p className="text-[11px] font-bold text-amber-700 mt-2 mr-1">لا توجد مستويات متاحة لعمرك الحالي</p>
        )}
        {fieldErrors.level && <p className="text-[11px] font-bold text-amber-700 mt-1 mr-1">{fieldErrors.level}</p>}
      </div>



      {/* Rewaya Picker - only when level has_rewaya */}
      {(() => {
        const selLevel = levels.find(l => l.title === formData.level);
        if (!selLevel?.has_rewaya || !selLevel.available_rewayas?.length) return null;
        return (
          <div className="rounded-2xl bg-primary/[0.02] p-3 sm:p-4 md:p-6">
            <div className="tour-step3-rewaya">
              <label htmlFor="rewaya-select" className="block text-sm font-bold text-primary mb-1.5">
                الرواية / القراءة <span className="text-red-500">*</span>
              </label>
              <div className="relative">
                <select
                  id="rewaya-select"
                  value={formData.selectedRewaya}
                  onChange={e => setFormData((p) => ({ ...p, selectedRewaya: e.target.value }))}
                  className="w-full bg-white border-2 border-primary/15 rounded-xl py-[14px] px-3 sm:px-4 text-primary text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all appearance-none shadow-sm"
                >
                  <option value="">-- اختر الرواية أو القراءة --</option>
                  {selLevel.available_rewayas.map(r => (
                    <option key={r} value={r}>{r}</option>
                  ))}
                </select>
                <ChevronDown size={14} className="sm:size-[16px] absolute left-2 sm:left-3 top-1/2 -translate-y-1/2 text-primary/30 pointer-events-none" />
              </div>
            </div>
          </div>
        );
      })()}

      {/* Branch Picker + Quantity - only when level has branches */}
      {(() => {
        const selLevel = levels.find(l => l.title === formData.level);
        if (!selLevel?.branches || selLevel.branches.length === 0) return null;
        return (
          <div className={`rounded-2xl ${fieldErrors.branch ? 'bg-amber-50/50 border-2 border-amber-400' : 'bg-primary/[0.02]'} p-3 sm:p-4 md:p-6`}>
            <label htmlFor="branch-select" className="block text-sm font-bold text-primary mb-1.5">
              الكمية المشاركة بها <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <select
                id="branch-select"
                value={branchName}
                onChange={e => { setBranchName(e.target.value); clearErr('branch'); }}
                className="w-full bg-white border-2 border-primary/15 rounded-xl py-[14px] px-3 sm:px-4 text-primary text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all appearance-none shadow-sm"
              >
                <option value="">-- اختر الكمية --</option>
                {selLevel.branches.map((b: string) => (
                  <option key={b} value={b}>{b}</option>
                ))}
              </select>
              <ChevronDown size={14} className="sm:size-[16px] absolute left-2 sm:left-3 top-1/2 -translate-y-1/2 text-primary/30 pointer-events-none" />
            </div>
            {fieldErrors.branch && <p className="text-[11px] font-bold text-amber-700 mt-1">{fieldErrors.branch}</p>}

            {/* Memorization amount selector - only when require_custom_amount is enabled */}
            {selLevel.require_custom_amount && (
              <div className="mt-4">
                <label htmlFor="memorization-select" className="block text-sm font-bold text-primary mb-1.5">
                  عدد الأجزاء المحفوظة
                </label>
                <div className="relative">
                  <select
                    id="memorization-select"
                    value={memorizationAmount ?? ''}
                    onChange={e => setMemorizationAmount(e.target.value ? parseInt(e.target.value) : null)}
                    className="w-full bg-white border-2 border-primary/15 rounded-xl py-[14px] px-3 sm:px-4 text-primary text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all appearance-none shadow-sm"
                  >
                    <option value="">-- اختر عدد الأجزاء --</option>
                    {Array.from({ length: 30 }, (_, i) => i + 1).map(n => (
                      <option key={n} value={n}>{n === 1 ? 'جزء واحد' : n === 2 ? 'جزئين' : `${n} أجزاء`}</option>
                    ))}
                  </select>
                  <ChevronDown size={14} className="sm:size-[16px] absolute left-2 sm:left-3 top-1/2 -translate-y-1/2 text-primary/30 pointer-events-none" />
                </div>
              </div>
            )}
          </div>
        );
      })()}

      {/* Custom Amount selector - 1-30 dropdown for ذوي الهمم */}
      {(() => {
        const selLevel = levels.find(l => l.title === formData.level);
        if (!selLevel?.require_custom_amount || (selLevel.branches && selLevel.branches.length > 0)) return null;
        return (
          <div className={`rounded-2xl ${fieldErrors.branch ? 'bg-amber-50/50 border-2 border-amber-400' : 'bg-primary/[0.02]'} p-3 sm:p-4 md:p-6`}>
            <label htmlFor="custom-amount-select" className="block text-sm font-bold text-primary mb-1">
              عدد الأجزاء المحفوظة <span className="text-red-500">*</span>
            </label>
            <p className="text-[10px] sm:text-[11px] text-primary/60 mb-2 sm:mb-3">اختر عدد الأجزاء التي تحفظها</p>
            <div className="relative">
              <select
                id="custom-amount-select"
                value={memorizationAmount ?? ''}
                onChange={e => {
                  const v = e.target.value ? parseInt(e.target.value) : null;
                  setMemorizationAmount(v);
                  setBranchName(v ? `${v} أجزاء` : '');
                  clearErr('branch');
                }}
                className="w-full bg-white border-2 border-primary/15 rounded-xl py-[14px] px-3 sm:px-4 text-primary text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all appearance-none shadow-sm"
              >
                <option value="">-- اختر عدد الأجزاء --</option>
                {Array.from({ length: 30 }, (_, i) => i + 1).map(n => (
                  <option key={n} value={n}>{n === 1 ? 'جزء واحد' : n === 2 ? 'جزئين' : `${n} أجزاء`}</option>
                ))}
              </select>
              <ChevronDown size={14} className="sm:size-[16px] absolute left-2 sm:left-3 top-1/2 -translate-y-1/2 text-primary/30 pointer-events-none" />
            </div>
            {fieldErrors.branch && <p className="text-[11px] font-bold text-amber-700 mt-1">{fieldErrors.branch}</p>}
          </div>
        );
      })()}
    </div>
  );
}
