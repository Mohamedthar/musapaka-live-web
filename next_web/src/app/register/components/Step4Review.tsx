import React, { useState, useEffect, useRef } from 'react';
import { UserCircle, Phone, MapPin } from 'lucide-react';
import { Turnstile } from '@marsidev/react-turnstile';
import type { RegistrationFormData } from '@/lib/database.types';
import Field from './Field';

interface Step4ReviewProps {
  formData: {
    memorizerName: string;
    memorizerPhone: string;
    memorizerAddress: string;
  };
  setFormData: React.Dispatch<React.SetStateAction<RegistrationFormData>>;
  isConfirmed: boolean;
  setIsConfirmed: (c: boolean) => void;
  setTurnstileToken: (t: string | null) => void;
  onTurnstileWidgetLoad?: (widgetId: string) => void;
}

export default function Step4Review({
  formData,
  setFormData,
  isConfirmed,
  setIsConfirmed,
  setTurnstileToken,
  onTurnstileWidgetLoad,
}: Step4ReviewProps) {
  const [turnstileError, setTurnstileError] = useState(false);
  const turnstileWidgetId = useRef<string | null>(null);
  const expiryTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const clearExpiryTimer = () => {
    if (expiryTimer.current) { clearTimeout(expiryTimer.current); expiryTimer.current = null; }
  };

  // Cleanup on unmount
  useEffect(() => () => clearExpiryTimer(), []);

  const handleTokenSuccess = (token: string) => {
    setTurnstileToken(token);
    setTurnstileError(false);
    clearExpiryTimer();
    // تجديد تلقائي قبل ٦٠ ثانية من انتهاء الصلاحية (الصلاحية ٣٠٠ ثانية)
    expiryTimer.current = setTimeout(() => {
      const id = turnstileWidgetId.current;
      if (id) {
        try {
          const ts = (window as unknown as { turnstile?: { reset: (id: string) => void; getResponse: (id: string) => string | undefined } }).turnstile;
          if (ts) ts.reset(id);
        } catch { /* ignore */ }
      }
      setTurnstileToken(null);
      setTurnstileError(true);
    }, 240_000); // 4 دقائق
  };

  const handleWidgetLoad = (widgetId: string) => {
    turnstileWidgetId.current = widgetId;
    onTurnstileWidgetLoad?.(widgetId);
  };

  return (
    <div className="space-y-5">
      <div className="mb-2">
        <h2 className="text-lg sm:text-xl font-black text-primary">بيانات المحفِّظ</h2>
        <p className="text-primary/60 text-sm mt-0.5">معلومات الشيخ أو المحفِّظ</p>
      </div>

      <div className="rounded-2xl bg-primary/[0.02] p-3 sm:p-4 md:p-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 md:gap-5 tour-step4-memorizer">
          <div className="sm:col-span-2">
            <Field
              label="اسم المحفِّظ / الشيخ"
              icon={<UserCircle size={17} />}
              value={formData.memorizerName}
              onChange={v => setFormData((p) => ({ ...p, memorizerName: v }))}
              placeholder="اسم الشيخ أو المحفِّظ"
              required
            />
          </div>
          <Field
            label="رقم هاتف المحفِّظ"
            icon={<Phone size={17} />}
            value={formData.memorizerPhone}
            onChange={v => setFormData((p) => ({ ...p, memorizerPhone: v }))}
            placeholder="01xxxxxxxxx"
            type="tel"
            required
          />
          <Field
            label="عنوان المحفِّظ"
            icon={<MapPin size={17} />}
            value={formData.memorizerAddress}
            onChange={v => setFormData((p) => ({ ...p, memorizerAddress: v }))}
            placeholder="المحافظة - المركز - القرية"
          />
          
          <label className="flex items-start gap-2 sm:gap-2.5 p-3 sm:p-3.5 bg-primary/[0.04] border border-primary/15 rounded-xl cursor-pointer sm:col-span-2 hover:bg-primary/[0.06] transition-colors">
            <input
              type="checkbox"
              checked={isConfirmed}
              onChange={e => setIsConfirmed(e.target.checked)}
              className="mt-0.5 w-4 h-4 sm:w-4.5 sm:h-4.5 rounded border-primary/30 accent-primary cursor-pointer flex-shrink-0"
              required
            />
            <span className="text-sm text-primary/70 font-semibold leading-relaxed select-none">
              أُقِرّ بأن جميع البيانات والمستندات المرفقة صحيحة ومطابقة للواقع، وأوافق على مراجعة الإدارة لها.
            </span>
          </label>
        </div>
      </div>

      {/* Turnstile Widget */}
      <div className="flex flex-col items-center py-2">
        {process.env.NODE_ENV === 'development' ? (
          <div className="flex items-center gap-2 px-5 py-2.5 bg-primary/[0.03] border-2 border-primary/15 rounded-xl text-xs font-bold text-primary/60">
            <span className="w-2 h-2 rounded-full bg-primary/40" />
            تم تجاوز التحقق الأمني (وضع التطوير)
          </div>
        ) : process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY ? (
          <>
            <Turnstile
              siteKey={process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY}
              options={{ appearance: 'always' }}
              onSuccess={handleTokenSuccess}
              onExpire={() => { clearExpiryTimer(); setTurnstileToken(null); setTurnstileError(true); }}
              onError={() => { clearExpiryTimer(); setTurnstileToken(null); setTurnstileError(true); }}
              onWidgetLoad={handleWidgetLoad}
            />
            {turnstileError && (
              <p className="text-amber-600 text-xs mt-2 font-semibold text-center">
                انتهت صلاحية التحقق الأمني — يرجى إعادة الضغط على المربع أعلاه
              </p>
            )}
          </>
        ) : (
          <div className="flex items-center gap-2 px-5 py-2.5 bg-primary/[0.03] border-2 border-primary/15 rounded-xl text-xs font-bold text-primary/60">
            <span className="w-2 h-2 rounded-full bg-primary/40" />
            تم تجاوز التحقق الأمني (وضع التطوير)
          </div>
        )}
      </div>
    </div>
  );
}
