import React from 'react';
import { CreditCard, UserCircle, ChevronDown, FileImage } from 'lucide-react';
import Field from './Field';

interface Step2OfficialProps {
  formData: {
    nationalId: string;
    age: string;
    gender: string;
  };
  setFormData: React.Dispatch<React.SetStateAction<any>>;
  fieldErrors: Record<string, string>;
  clearErr: (key: string) => void;
  isCheckingId: boolean;
  idExists: boolean;
  birthCertPreview: string | null;
  handleImagePick: (e: React.ChangeEvent<HTMLInputElement>, type: 'profile' | 'birthCert') => void;
}

export default function Step2Official({
  formData,
  setFormData,
  fieldErrors,
  clearErr,
  isCheckingId,
  idExists,
  birthCertPreview,
  handleImagePick
}: Step2OfficialProps) {
  return (
    <div className="space-y-5">
      <div className="mb-6">
        <h2 className="text-xl font-black text-slate-900">البيانات الرسمية</h2>
        <p className="text-slate-500 text-sm mt-1">للتحقق من السن والمستوى</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 lg:gap-8">
        <div className="md:col-span-2 tour-step2-info">
          <Field
            label="الرقم القومي (14 رقم)"
            icon={<CreditCard size={17} />}
            value={formData.nationalId}
            onChange={v => {
              setFormData((p: any) => {
                const n = { ...p, nationalId: v };
                if (v.trim().length === 14 && /^\d+$/.test(v.trim())) {
                  const c = parseInt(v.trim()[0]);
                  if (c === 2 || c === 3) {
                    const y = (c === 2 ? 1900 : 2000) + parseInt(v.trim().substring(1, 3));
                    const m = parseInt(v.trim().substring(3, 5));
                    const d = parseInt(v.trim().substring(5, 7));
                    const bd = new Date(y, m - 1, d);
                    const now = new Date();
                    let age = now.getFullYear() - bd.getFullYear();
                    if (now.getMonth() < bd.getMonth() || (now.getMonth() === bd.getMonth() && now.getDate() < bd.getDate())) age--;
                    if (age >= 0 && age < 100) n.age = age.toString();
                  }
                  n.gender = parseInt(v.trim()[12]) % 2 !== 0 ? 'ذكر' : 'أنثى';
                }
                return n;
              });
              clearErr('nationalId');
            }}
            placeholder="أدخل الـ 14 رقماً"
            type="tel"
            required
            loading={isCheckingId}
            error={fieldErrors.nationalId || (idExists ? "هذا الرقم القومي مسجل مسبقاً" : undefined)}
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <Field
              label="العمر"
              icon={<UserCircle size={17} />}
              value={formData.age}
              onChange={v => {
                setFormData((p: any) => ({ ...p, age: v }));
                clearErr('age');
              }}
              placeholder="مثال: 18"
              type="number"
              required
              error={fieldErrors.age}
            />
          </div>
          <div>
            <label className="block text-sm font-bold text-slate-700 mb-2">النوع</label>
            <div className="relative">
              <select
                value={formData.gender}
                onChange={e => {
                  setFormData((p: any) => ({ ...p, gender: e.target.value }));
                  clearErr('gender');
                }}
                className={`w-full bg-slate-50 border ${fieldErrors.gender ? 'border-amber-400' : 'border-slate-200'} rounded-xl py-3 px-4 text-slate-800 text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-slate-900 appearance-none`}
              >
                <option value="ذكر">ذكر</option>
                <option value="أنثى">أنثى</option>
              </select>
              <ChevronDown size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>
            {fieldErrors.gender && <p className="text-[11px] font-bold text-amber-600 mt-1 mr-1">{fieldErrors.gender}</p>}
          </div>
        </div>

        {/* Birth Cert */}
        <div className="tour-step2-cert">
          <label className="block text-sm font-bold text-slate-700 mb-2">
            شهادة الميلاد / الهوية <span className="text-red-500">*</span>
          </label>
          <label
            className={`flex flex-col items-center justify-center w-full h-32 md:h-auto md:flex-1 min-h-[5rem] border-2 border-dashed rounded-xl cursor-pointer transition-all ${fieldErrors.birthCert ? 'border-amber-400 bg-amber-50/50' : birthCertPreview ? 'border-emerald-400 bg-emerald-50/30' : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50/50'}`}
            style={{ height: birthCertPreview ? '100%' : '5rem' }}
          >
            {birthCertPreview ? (
              <div className="relative w-full h-full p-2 min-h-[8rem]">
                <img src={birthCertPreview} alt="شهادة الميلاد" className="w-full h-full object-contain rounded-xl max-h-48" />
                <div className="absolute inset-2 bg-black/30 rounded-xl opacity-0 hover:opacity-100 flex items-center justify-center transition-opacity">
                  <span className="text-white text-xs font-bold bg-black/50 px-3 py-1.5 rounded-lg">تغيير</span>
                </div>
              </div>
            ) : (
              <div className="flex items-center gap-3 text-slate-400 py-3">
                <FileImage size={24} />
                <div>
                  <p className="font-bold text-sm text-slate-600">اضغط لرفع المستند</p>
                  <p className="text-xs">صورة واضحة، حجم أقصاه 5MB</p>
                </div>
              </div>
            )}
            <input type="file" className="hidden" accept="image/*" onChange={e => handleImagePick(e, 'birthCert')} />
          </label>
          {fieldErrors.birthCert && <p className="text-[11px] font-bold text-amber-600 mt-1 mr-1">{fieldErrors.birthCert}</p>}
        </div>
      </div>
    </div>
  );
}
