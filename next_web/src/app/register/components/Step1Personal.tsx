import React from 'react';
import { User, Camera, UserCircle, Phone, MapPin } from 'lucide-react';
import Field from './Field';

interface Step1PersonalProps {
  formData: {
    name: string;
    phone: string;
    location: string;
  };
  setFormData: React.Dispatch<React.SetStateAction<any>>;
  fieldErrors: Record<string, string>;
  clearErr: (key: string) => void;
  isCheckingName: boolean;
  nameExists: boolean;
  profilePreview: string | null;
  handleImagePick: (e: React.ChangeEvent<HTMLInputElement>, type: 'profile' | 'birthCert') => void;
}

export default function Step1Personal({
  formData,
  setFormData,
  fieldErrors,
  clearErr,
  isCheckingName,
  nameExists,
  profilePreview,
  handleImagePick
}: Step1PersonalProps) {
  return (
    <div className="space-y-5">
      <div className="mb-6">
        <h2 className="text-xl font-black text-slate-900">البيانات الشخصية</h2>
        <p className="text-slate-500 text-sm mt-1">معلومات التواصل الأساسية</p>
      </div>

      {/* Profile Photo */}
      <div className="flex flex-col items-center mb-6 tour-photo">
        <div className="relative group w-24 h-24">
          <div className={`w-24 h-24 rounded-full border-2 overflow-hidden bg-slate-100 flex items-center justify-center ${fieldErrors.profile ? 'border-red-400' : 'border-slate-200'}`}>
            {profilePreview ? (
              <img src={profilePreview} alt="الصورة الشخصية" className="w-full h-full object-cover" />
            ) : (
              <User size={36} className="text-slate-300" />
            )}
          </div>
          <label className="absolute inset-0 bg-black/50 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 cursor-pointer transition-opacity">
            <Camera size={18} className="text-white" />
            <input type="file" accept="image/*" className="hidden" onChange={e => handleImagePick(e, 'profile')} />
          </label>
        </div>
        <p className="text-xs text-slate-400 font-semibold mt-2">صورة شخصية <span className="text-red-500">*</span></p>
        {fieldErrors.profile && <p className="text-[11px] font-bold text-amber-600 mt-1">{fieldErrors.profile}</p>}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 lg:gap-8 tour-name">
        <div className="md:col-span-2">
          <Field
            label="الاسم الرباعي"
            icon={<UserCircle size={17} />}
            value={formData.name}
            onChange={v => {
              setFormData((p: any) => ({ ...p, name: v }));
              clearErr('name');
            }}
            placeholder="محمد أحمد محمود علي"
            required
            loading={isCheckingName}
            error={fieldErrors.name || (nameExists ? "هذا الاسم مسجل مسبقاً في النظام" : undefined)}
          />
        </div>
        <Field
          label="رقم هاتف الطالب / ولي الأمر"
          icon={<Phone size={17} />}
          value={formData.phone}
          onChange={v => {
            setFormData((p: any) => ({ ...p, phone: v }));
            clearErr('phone');
          }}
          placeholder="01xxxxxxxxx"
          type="tel"
          required
          error={fieldErrors.phone}
        />
        <Field
          label="العنوان"
          icon={<MapPin size={17} />}
          value={formData.location}
          onChange={v => {
            setFormData((p: any) => ({ ...p, location: v }));
            clearErr('location');
          }}
          placeholder="المحافظة - المركز - القرية"
          required
          error={fieldErrors.location}
        />
      </div>
    </div>
  );
}
