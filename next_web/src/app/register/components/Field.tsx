import React from 'react';
import { CheckCircle2 } from 'lucide-react';

interface FieldProps {
  label: string;
  icon: React.ReactNode;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
  required?: boolean;
  loading?: boolean;
  error?: string;
}

export default function Field({
  label,
  icon,
  value,
  onChange,
  placeholder,
  type = 'text',
  required = false,
  loading = false,
  error
}: FieldProps) {
  const isNumber = type === 'tel' || type === 'number';
  return (
    <div className="group/field">
      <label className="block text-sm font-bold text-slate-700 mb-2 transition-colors group-focus-within/field:text-emerald-700">
        {label}
        {required && <span className="text-red-500 mr-1">*</span>}
      </label>
      <div className="relative">
        <div className="absolute inset-y-0 right-0 pr-4 flex items-center text-slate-400 group-focus-within/field:text-emerald-500 transition-colors pointer-events-none">
          {icon}
        </div>
        <input 
          type={type} 
          value={value} 
          onChange={e => onChange(e.target.value)} 
          placeholder={placeholder} 
          required={required}
          dir={isNumber ? 'ltr' : undefined}
          style={{ textAlign: isNumber ? 'right' : undefined }}
          className={`w-full bg-slate-50 border ${error ? 'border-amber-400' : 'border-slate-200'} rounded-xl py-3 pl-12 pr-10 text-slate-800 text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-slate-900 focus:bg-white transition-all placeholder:text-slate-400`} 
        />
        {loading && (
          <div className="absolute left-4 top-1/2 -translate-y-1/2">
            <div className="w-4 h-4 border-2 border-slate-200 border-t-emerald-600 rounded-full animate-spin" />
          </div>
        )}
        {!loading && error && (
          <div className="absolute left-4 top-1/2 -translate-y-1/2 text-amber-500">
            <CheckCircle2 size={16} />
          </div>
        )}
      </div>
      {error && <p className="text-[11px] font-bold text-amber-600 mt-1.5 mr-1.5">{error}</p>}
    </div>
  );
}
