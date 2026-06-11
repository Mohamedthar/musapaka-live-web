import React from 'react';
import { Camera, UserCircle, Phone, MapPin, CreditCard, ChevronDown, FileImage } from 'lucide-react';
import type { RegistrationFormData } from '@/lib/database.types';
import Field from './Field';

interface Step1PersonalProps {
  formData: {
    name: string;
    phone: string;
    location: string;
    nationalId: string;
    birthDate: string;
    gender: string;
  };
  setFormData: React.Dispatch<React.SetStateAction<RegistrationFormData>>;
  fieldErrors: Record<string, string>;
  clearErr: (key: string) => void;
  isCheckingName: boolean;
  nameExists: boolean;
  isCheckingId: boolean;
  idExists: boolean;
  profilePreview: string | null;
  birthCertPreview: string | null;
  handleImagePick: (e: React.ChangeEvent<HTMLInputElement>, type: 'profile' | 'birthCert') => void;
}

export default function Step1Personal({
  formData,
  setFormData,
  fieldErrors,
  clearErr,
  isCheckingName,
  nameExists,
  isCheckingId,
  idExists,
  profilePreview,
  birthCertPreview,
  handleImagePick
}: Step1PersonalProps) {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg sm:text-xl font-black text-primary">البيانات الشخصية</h2>
        <p className="text-primary/50 text-sm mt-0.5">جميع بيانات الطالب الأساسية</p>
      </div>

      {/* Fields Section */}
      <div className="rounded-2xl bg-primary/[0.02] p-3 sm:p-4 md:p-6 space-y-4 sm:space-y-5">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 md:gap-5">
          {/* الاسم + العنوان - جنب بعض في الشاشات الكبيرة */}
          <div className="sm:col-span-2 lg:col-span-1">
            <Field
              label="الاسم الرباعي"
              icon={<UserCircle size={17} />}
              value={formData.name}
              onChange={v => {
                setFormData((p) => ({ ...p, name: v }));
                clearErr('name');
              }}
              placeholder="محمد أحمد محمود علي"
              required
              loading={isCheckingName}
              error={fieldErrors.name || (nameExists ? "هذا الاسم مسجل مسبقاً في النظام" : undefined)}
            />
          </div>
          <div className="sm:col-span-2 lg:col-span-1">
            <Field
              label="العنوان"
              icon={<MapPin size={17} />}
              value={formData.location}
              onChange={v => {
                setFormData((p) => ({ ...p, location: v }));
                clearErr('location');
              }}
              placeholder="المحافظة - المركز - القرية"
              required
              error={fieldErrors.location}
            />
          </div>

          {/* الهاتف */}
          <Field
            label="رقم هاتف الطالب / ولي الأمر"
            icon={<Phone size={17} />}
            value={formData.phone}
            onChange={v => {
              setFormData((p) => ({ ...p, phone: v }));
              clearErr('phone');
            }}
            placeholder="01xxxxxxxxx"
            type="tel"
            required
            error={fieldErrors.phone}
          />

          {/* الرقم القومي */}
          <Field
            label="الرقم القومي (14 رقم)"
            icon={<CreditCard size={17} />}
            value={formData.nationalId}
            onChange={v => {
              setFormData((p) => ({ ...p, nationalId: v }));
              clearErr('nationalId');
            }}
            placeholder="أدخل الـ 14 رقماً"
            type="tel"
            required
            loading={isCheckingId}
            error={fieldErrors.nationalId || (idExists ? "هذا الرقم القومي مسجل مسبقاً" : undefined)}
          />

          {/* تاريخ الميلاد + النوع */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 sm:col-span-2">
            <div>
              <label className="block text-sm font-bold text-primary mb-1.5">تاريخ الميلاد <span className="text-red-500">*</span></label>
              <div className="grid grid-cols-3 gap-1.5 sm:gap-2">
                {/* اليوم */}
                <div className="relative">
                  <select
                    value={formData.birthDate ? formData.birthDate.split('-')[2] ?? '' : ''}
                    onChange={e => {
                      const [y = '', m = ''] = (formData.birthDate || '').split('-');
                      setFormData((p) => ({ ...p, birthDate: [y, m, e.target.value.padStart(2, '0')].join('-') }));
                      clearErr('birthDate');
                    }}
                    className={`w-full bg-white border-2 ${fieldErrors.birthDate ? 'border-amber-400' : 'border-primary/20'} rounded-xl py-[11px] px-1.5 sm:px-2 text-primary text-[13px] sm:text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all appearance-none shadow-sm cursor-pointer text-center`}
                  >
                    <option value="">اليوم</option>
                    {Array.from({ length: 31 }, (_, i) => (
                      <option key={i + 1} value={String(i + 1).padStart(2, '0')}>{i + 1}</option>
                    ))}
                  </select>
                </div>
                {/* الشهر */}
                <div className="relative">
                  <select
                    value={formData.birthDate ? formData.birthDate.split('-')[1] ?? '' : ''}
                    onChange={e => {
                      const [y = '', , d = ''] = (formData.birthDate || '').split('-');
                      setFormData((p) => ({ ...p, birthDate: [y, e.target.value.padStart(2, '0'), d].join('-') }));
                      clearErr('birthDate');
                    }}
                    className={`w-full bg-white border-2 ${fieldErrors.birthDate ? 'border-amber-400' : 'border-primary/20'} rounded-xl py-[11px] px-1.5 sm:px-2 text-primary text-[13px] sm:text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all appearance-none shadow-sm cursor-pointer text-center`}
                  >
                    <option value="">الشهر</option>
                    {['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'].map((m, i) => (
                      <option key={i} value={String(i + 1).padStart(2, '0')}>{m}</option>
                    ))}
                  </select>
                </div>
                {/* السنة */}
                <div className="relative">
                  <select
                    value={formData.birthDate ? formData.birthDate.split('-')[0] ?? '' : ''}
                    onChange={e => {
                      const [, m = '', d = ''] = (formData.birthDate || '').split('-');
                      setFormData((p) => ({ ...p, birthDate: [e.target.value, m, d].join('-') }));
                      clearErr('birthDate');
                    }}
                    className={`w-full bg-white border-2 ${fieldErrors.birthDate ? 'border-amber-400' : 'border-primary/20'} rounded-xl py-[11px] px-1.5 sm:px-2 text-primary text-[13px] sm:text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all appearance-none shadow-sm cursor-pointer text-center`}
                  >
                    <option value="">السنة</option>
                    {Array.from({ length: 80 }, (_, i) => {
                      const y = new Date().getFullYear() - i;
                      return <option key={y} value={String(y)}>{y}</option>;
                    })}
                  </select>
                </div>
              </div>
              {fieldErrors.birthDate && <p className="text-[11px] font-bold text-amber-600 mt-1 mr-1">{fieldErrors.birthDate}</p>}
            </div>

            {/* النوع */}
            <div>
              <label className="block text-sm font-bold text-primary mb-1.5">النوع</label>
              <div className="relative">
                <select
                  value={formData.gender}
                  onChange={e => {
                    setFormData((p) => ({ ...p, gender: e.target.value }));
                    clearErr('gender');
                  }}
                  className={`w-full bg-white border-2 ${fieldErrors.gender ? 'border-amber-400' : 'border-primary/20'} rounded-xl py-[11px] px-3 sm:px-4 text-primary text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all appearance-none shadow-sm`}
                >
                  <option value="" disabled>-- اختر النوع --</option>
                  <option value="ذكر">ذكر</option>
                  <option value="أنثى">أنثى</option>
                </select>
                <ChevronDown size={14} className="sm:size-[16px] absolute left-3 sm:left-4 top-1/2 -translate-y-1/2 text-primary/30 pointer-events-none" />
              </div>
              {fieldErrors.gender && <p className="text-[11px] font-bold text-amber-600 mt-1 mr-1">{fieldErrors.gender}</p>}
            </div>
          </div>
        </div>
      </div>

      {/* الصور - تحت الحقول */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
        {/* Profile Photo */}
        <div className="rounded-2xl bg-primary/[0.02] p-3 sm:p-4 md:p-6">
          <label className="block text-sm font-bold text-primary mb-3">
            صورة شخصية <span className="text-red-500">*</span>
          </label>
          <label
            className={`flex flex-col items-center justify-center w-full min-h-[6rem] border-2 border-dashed rounded-xl cursor-pointer transition-all ${fieldErrors.profile ? 'border-amber-400 bg-amber-50/50' : profilePreview ? 'border-primary/40 bg-primary/[0.03]' : 'border-primary/20 hover:border-primary/40 hover:bg-primary/[0.03]'}`}
          >
            {profilePreview ? (
               <div className="relative w-full p-2 min-h-[8rem]">
                <img src={profilePreview} alt="الصورة الشخصية" className="w-full h-full object-contain rounded-xl max-h-48 mx-auto" />
                <div className="absolute inset-2 bg-primary/40 rounded-xl opacity-0 hover:opacity-100 flex items-center justify-center transition-opacity backdrop-blur-sm">
                  <span className="text-white text-xs font-bold bg-primary/70 px-3 py-1.5 rounded-lg">تغيير</span>
                </div>
              </div>
            ) : (
              <div className="flex flex-col items-center gap-2 text-primary/40 py-5">
                <div className="w-10 h-10 rounded-full bg-primary/[0.06] flex items-center justify-center">
                  <Camera size={20} />
                </div>
                <div className="text-center">
                  <p className="font-bold text-sm text-primary/60">اضغط لرفع الصورة</p>
                  <p className="text-xs text-primary/40 mt-0.5">صورة واضحة، حجم أقصاه 5MB</p>
                </div>
              </div>
            )}
            <input type="file" className="hidden" accept="image/*" onChange={e => handleImagePick(e, 'profile')} />
          </label>
          {fieldErrors.profile && <p className="text-[11px] font-bold text-amber-600 mt-1 mr-1">{fieldErrors.profile}</p>}
        </div>

        {/* Birth Certificate */}
        <div className="rounded-2xl bg-primary/[0.02] p-3 sm:p-4 md:p-6">
          <label className="block text-sm font-bold text-primary mb-3">
            البطاقة الشخصية أو شهادة الميلاد <span className="text-red-500">*</span>
          </label>
          <label
            className={`flex flex-col items-center justify-center w-full min-h-[6rem] border-2 border-dashed rounded-xl cursor-pointer transition-all ${fieldErrors.birthCert ? 'border-amber-400 bg-amber-50/50' : birthCertPreview ? 'border-primary/40 bg-primary/[0.03]' : 'border-primary/20 hover:border-primary/40 hover:bg-primary/[0.03]'}`}
          >
            {birthCertPreview ? (
               <div className="relative w-full p-2 min-h-[8rem]">
                <img src={birthCertPreview} alt="شهادة الميلاد" className="w-full h-full object-contain rounded-xl max-h-48 mx-auto" />
                <div className="absolute inset-2 bg-primary/40 rounded-xl opacity-0 hover:opacity-100 flex items-center justify-center transition-opacity backdrop-blur-sm">
                  <span className="text-white text-xs font-bold bg-primary/70 px-3 py-1.5 rounded-lg">تغيير</span>
                </div>
              </div>
            ) : (
              <div className="flex flex-col items-center gap-2 text-primary/40 py-5">
                <div className="w-10 h-10 rounded-full bg-primary/[0.06] flex items-center justify-center">
                  <FileImage size={20} />
                </div>
                <div className="text-center">
                  <p className="font-bold text-sm text-primary/60">اضغط لرفع المستند</p>
                  <p className="text-xs text-primary/40 mt-0.5">صورة واضحة، حجم أقصاه 5MB</p>
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
