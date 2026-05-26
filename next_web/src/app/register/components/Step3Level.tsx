import React from 'react';
import { ChevronDown, Search, CheckCircle2, BookOpen } from 'lucide-react';
import { toast } from 'react-hot-toast';
import type { CompetitionLevel } from '@/lib/database.types';

interface Step3LevelProps {
  formData: {
    level: string;
    selectedRewaya: string;
  };
  setFormData: React.Dispatch<React.SetStateAction<any>>;
  fieldErrors: Record<string, string>;
  clearErr: (key: string) => void;
  levels: CompetitionLevel[];
  filteredLevels: CompetitionLevel[];
  levelSearch: string;
  setLevelSearch: (q: string) => void;
  levelDropdownOpen: boolean;
  setLevelDropdownOpen: (open: boolean) => void;
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
  filteredLevels,
  levelSearch,
  setLevelSearch,
  levelDropdownOpen,
  setLevelDropdownOpen,
  levelCounts,
  branchName,
  setBranchName,
  memorizationAmount,
  setMemorizationAmount
}: Step3LevelProps) {
  return (
    <div className="space-y-5 relative">
      {levelDropdownOpen && (
        <div className="fixed inset-0 z-10" onClick={() => setLevelDropdownOpen(false)} />
      )}

      <div className="mb-2">
        <h2 className="text-xl font-black text-slate-900">اختيار المستوى</h2>
        <p className="text-slate-500 text-sm mt-1">حدد الفرع المناسب لك</p>
      </div>

      {/* Custom Dropdown Selector */}
      <div className="relative z-20 tour-step3-level">
        <label className="block text-sm font-bold text-slate-700 mb-2">
          مستوى المسابقة <span className="text-red-500">*</span>
        </label>
        <button
          type="button"
          onClick={() => setLevelDropdownOpen(!levelDropdownOpen)}
          className="w-full flex items-center justify-between bg-slate-50 border border-slate-200 rounded-xl py-3 px-4 text-right text-slate-800 text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-slate-900 transition-all hover:bg-slate-100/50"
        >
          {(() => {
            const sel = levels.find(l => l.title === formData.level);
            if (sel) {
              return (
                <div className="flex flex-col text-right">
                  <span className="text-slate-800 font-bold text-sm">{sel.content}</span>
                  <span className="text-xs text-slate-500 font-semibold mt-0.5">{sel.title}</span>
                </div>
              );
            }
            return <span className="text-slate-400 text-xs font-bold">-- اختر مستوى المسابقة --</span>;
          })()}
          <ChevronDown size={16} className={`text-slate-400 transition-transform duration-200 ${levelDropdownOpen ? 'rotate-180 text-slate-900' : ''}`} />
        </button>

        {levelDropdownOpen && (
          <div className="absolute right-0 left-0 mt-2 bg-white border border-slate-200 rounded-2xl shadow-xl p-2.5 space-y-2.5 z-30 animate-fade-in text-right">
            {/* Search Input */}
            <div className="relative">
              <input
                type="text"
                value={levelSearch}
                onChange={e => setLevelSearch(e.target.value)}
                placeholder="ابحث عن المستوى..."
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 pr-9 pl-4 text-xs font-semibold text-slate-800 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:bg-white transition-all placeholder:text-slate-400"
              />
              <Search size={14} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>

            {/* List */}
            <div className="flex flex-col gap-1 max-h-60 overflow-y-auto custom-scroll pl-1 pr-1 pb-1">
              {filteredLevels.length === 0 ? (
                <p className="text-xs text-slate-400 text-center py-4 font-bold">لا توجد مستويات مطابقة للبحث</p>
              ) : (
                filteredLevels.map(l => {
                  const count = levelCounts[l.title] || 0;
                  const isFull = l.max_capacity != null && count >= l.max_capacity;
                  const isSelected = formData.level === l.title;
                  return (
                    <button
                      type="button"
                      key={l.title}
                      disabled={isFull}
                      onClick={() => {
                        if (isFull) {
                          toast.error('هذا المستوى ممتلئ تماماً');
                          return;
                        }
                        const defaultRewaya = l.has_rewaya && l.available_rewayas?.length ? l.available_rewayas[0] : '';
                        setFormData((p: any) => ({ ...p, level: l.title, selectedRewaya: defaultRewaya }));
                        setBranchName(''); // reset branch when level changes
                        setMemorizationAmount(null);
                        clearErr('level');
                        setLevelDropdownOpen(false);
                        setLevelSearch('');
                      }}
                      className={`w-full flex items-center justify-between p-3 rounded-lg text-right transition-all text-xs ${isFull ? 'opacity-50 cursor-not-allowed bg-slate-50' : isSelected ? 'bg-slate-50 text-slate-950 font-bold' : 'hover:bg-slate-50 text-slate-700 hover:text-slate-950'}`}
                    >
                      <div className="flex items-center gap-2 min-w-0 flex-1">
                        <div className="w-4 h-4 flex items-center justify-center flex-shrink-0">
                          {isSelected && <CheckCircle2 size={14} className="text-slate-900" />}
                        </div>
                        <div className="min-w-0 text-right">
                          <p className={`font-bold ${isFull ? 'text-slate-400' : 'text-slate-950'}`}>{l.content}</p>
                          <p className="text-[10px] text-slate-400 font-semibold">{l.title}</p>
                        </div>
                      </div>

                      <div className="flex items-center gap-1.5 mr-4 flex-shrink-0">
                        {(l.min_age || l.max_age) && (
                          <span className="text-[9px] font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md">
                            {l.min_age ? `فوق ${l.min_age}` : ''}{l.min_age && l.max_age ? ' — ' : ''}{l.max_age ? `${l.max_age} فأقل` : ''} عام
                          </span>
                        )}
                        {isFull ? (
                          <span className="text-[9px] font-bold text-red-600 bg-red-50 px-2 py-0.5 rounded-md">
                            ممتلئ
                          </span>
                        ) : l.max_capacity != null ? (
                          <span className="text-[9px] font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md">
                            {count}/{l.max_capacity}
                          </span>
                        ) : null}
                      </div>
                    </button>
                  );
                })
              )}
            </div>
          </div>
        )}
      </div>
      {fieldErrors.level && <p className="text-[11px] font-bold text-amber-600 mr-1">{fieldErrors.level}</p>}



      {/* Rewaya Picker - only when level has_rewaya */}
      {(() => {
        const selLevel = levels.find(l => l.title === formData.level);
        if (!selLevel?.has_rewaya || !selLevel.available_rewayas?.length) return null;
        return (
          <div className="tour-step3-rewaya">
            <label className="block text-sm font-bold text-slate-700 mb-2">
              الرواية / القراءة <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <select
                value={formData.selectedRewaya}
                onChange={e => setFormData((p: any) => ({ ...p, selectedRewaya: e.target.value }))}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 px-4 text-slate-800 text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-slate-900 appearance-none"
              >
                <option value="">-- اختر الرواية أو القراءة --</option>
                {selLevel.available_rewayas.map(r => (
                  <option key={r} value={r}>{r}</option>
                ))}
              </select>
              <ChevronDown size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>
          </div>
        );
      })()}

      {/* Branch Picker + Quantity - only when level has branches */}
      {(() => {
        const selLevel = levels.find(l => l.title === formData.level);
        if (!selLevel?.branches || selLevel.branches.length === 0) return null;
        return (
          <div className={`p-5 rounded-2xl border ${fieldErrors.branch ? 'border-amber-400 bg-amber-50/50' : 'border-slate-200 bg-slate-50/50'}`}>
            <label className="block text-sm font-bold text-slate-700 mb-2">
              الكمية المشاركة بها <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <select
                value={branchName}
                onChange={e => { setBranchName(e.target.value); clearErr('branch'); }}
                className="w-full bg-white border border-slate-200 rounded-xl py-3 px-4 text-slate-800 text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-slate-900 appearance-none"
              >
                <option value="">-- اختر الكمية --</option>
                {selLevel.branches.map((b: string) => (
                  <option key={b} value={b}>{b}</option>
                ))}
              </select>
              <ChevronDown size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>
            {fieldErrors.branch && <p className="text-[11px] font-bold text-amber-600 mt-1">{fieldErrors.branch}</p>}

            {/* Memorization amount selector for branches */}
            <div className="mt-4">
              <label className="block text-sm font-bold text-slate-700 mb-2">
                عدد الأجزاء المحفوظة
              </label>
              <div className="relative">
                <select
                  value={memorizationAmount ?? ''}
                  onChange={e => setMemorizationAmount(e.target.value ? parseInt(e.target.value) : null)}
                  className="w-full bg-white border border-slate-200 rounded-xl py-3 px-4 text-slate-800 text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-slate-900 appearance-none"
                >
                  <option value="">-- اختر عدد الأجزاء --</option>
                  {Array.from({ length: 30 }, (_, i) => i + 1).map(n => (
                    <option key={n} value={n}>{n === 1 ? 'جزء واحد' : n === 2 ? 'جزئين' : `${n} أجزاء`}</option>
                  ))}
                </select>
                <ChevronDown size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
              </div>
            </div>
          </div>
        );
      })()}

      {/* Custom Amount selector - 1-30 dropdown for ذوي الهمم */}
      {(() => {
        const selLevel = levels.find(l => l.title === formData.level);
        if (!selLevel?.require_custom_amount || (selLevel.branches && selLevel.branches.length > 0)) return null;
        return (
          <div className={`p-5 rounded-2xl border ${fieldErrors.branch ? 'border-amber-400 bg-amber-50/50' : 'border-slate-200 bg-slate-50/50'}`}>
            <label className="block text-sm font-bold text-slate-700 mb-1">
              عدد الأجزاء المحفوظة <span className="text-red-500">*</span>
            </label>
            <p className="text-[11px] text-slate-500 mb-2">اختر عدد الأجزاء التي تحفظها</p>
            <div className="relative">
              <select
                value={memorizationAmount ?? ''}
                onChange={e => {
                  const v = e.target.value ? parseInt(e.target.value) : null;
                  setMemorizationAmount(v);
                  setBranchName(v ? `${v} أجزاء` : '');
                  clearErr('branch');
                }}
                className="w-full bg-white border border-slate-200 rounded-xl py-3 px-4 text-slate-800 text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-slate-900 appearance-none"
              >
                <option value="">-- اختر عدد الأجزاء --</option>
                {Array.from({ length: 30 }, (_, i) => i + 1).map(n => (
                  <option key={n} value={n}>{n === 1 ? 'جزء واحد' : n === 2 ? 'جزئين' : `${n} أجزاء`}</option>
                ))}
              </select>
              <ChevronDown size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>
            {fieldErrors.branch && <p className="text-[11px] font-bold text-amber-600 mt-1">{fieldErrors.branch}</p>}
          </div>
        );
      })()}
    </div>
  );
}
