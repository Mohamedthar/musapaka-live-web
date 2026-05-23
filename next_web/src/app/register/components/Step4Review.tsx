import React, { useState } from 'react';
import { UserCircle, Phone, MapPin } from 'lucide-react';
import { Turnstile } from '@marsidev/react-turnstile';
import Field from './Field';

interface Step4ReviewProps {
  formData: {
    memorizerName: string;
    memorizerPhone: string;
    memorizerAddress: string;
  };
  setFormData: React.Dispatch<React.SetStateAction<any>>;
  isConfirmed: boolean;
  setIsConfirmed: (c: boolean) => void;
  setTurnstileToken: (t: string | null) => void;
}

export default function Step4Review({
  formData,
  setFormData,
  isConfirmed,
  setIsConfirmed,
  setTurnstileToken
}: Step4ReviewProps) {
  const [turnstileError, setTurnstileError] = useState(false);

  return (
    <div className="space-y-5">
      <div className="mb-6">
        <h2 className="text-xl font-black text-slate-900">بيانات المحفِّظ</h2>
        <p className="text-slate-500 text-sm mt-1">معلومات الشيخ أو المحفِّظ</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 lg:gap-8 tour-step4-memorizer">
        <div className="md:col-span-2">
          <Field
            label="اسم المحفِّظ / الشيخ"
            icon={<UserCircle size={17} />}
            value={formData.memorizerName}
            onChange={v => setFormData((p: any) => ({ ...p, memorizerName: v }))}
            placeholder="اسم الشيخ أو المحفِّظ"
            required
          />
        </div>
        <Field
          label="رقم هاتف المحفِّظ"
          icon={<Phone size={17} />}
          value={formData.memorizerPhone}
          onChange={v => setFormData((p: any) => ({ ...p, memorizerPhone: v }))}
          placeholder="01xxxxxxxxx"
          type="tel"
        />
        <Field
          label="عنوان المحفِّظ"
          icon={<MapPin size={17} />}
          value={formData.memorizerAddress}
          onChange={v => setFormData((p: any) => ({ ...p, memorizerAddress: v }))}
          placeholder="المحافظة - المركز - القرية"
        />
        
        <label className="flex items-start gap-2.5 p-3.5 bg-slate-50 border border-slate-200/80 rounded-xl cursor-pointer md:col-span-2 hover:bg-slate-100/80 transition-colors">
          <input
            type="checkbox"
            checked={isConfirmed}
            onChange={e => setIsConfirmed(e.target.checked)}
            className="mt-0.5 w-4.5 h-4.5 rounded border-slate-300 accent-slate-900 cursor-pointer flex-shrink-0"
            required
          />
          <span className="text-xs sm:text-sm text-slate-700 font-semibold leading-relaxed select-none">
            أُقِرّ بأن جميع البيانات والمستندات المرفقة صحيحة ومطابقة للواقع، وأوافق على مراجعة الإدارة لها.
          </span>
        </label>
      </div>

      {/* Turnstile Widget */}
      <div className="flex flex-col items-center py-2">
        <Turnstile
          siteKey={process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY!}
          onSuccess={(token) => { setTurnstileToken(token); setTurnstileError(false); }}
          onExpire={() => { setTurnstileToken(null); setTurnstileError(true); }}
          onError={() => { setTurnstileToken(null); setTurnstileError(true); }}
        />
        {turnstileError && (
          <p className="text-red-600 text-xs mt-2 font-semibold">
            فشل التحقق الأمني. يرجى إعادة المحاولة أو تحديث الصفحة.
          </p>
        )}
      </div>
    </div>
  );
}
