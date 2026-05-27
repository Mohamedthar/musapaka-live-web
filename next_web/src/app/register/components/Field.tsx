import React from 'react';
import { AlertTriangle } from 'lucide-react';

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
      <label className="block text-sm font-bold text-primary mb-1 sm:mb-1.5">
        {label}
        {required && <span className="text-red-500 mr-1">*</span>}
      </label>
      <div className="relative">
        <div className="absolute inset-y-0 right-0 pr-3 sm:pr-4 flex items-center text-primary/30 group-focus-within/field:text-primary transition-colors pointer-events-none">
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
          className={`w-full bg-white border-2 ${error ? 'border-amber-400' : 'border-primary/20 group-focus-within/field:border-primary/50'} rounded-xl py-[14px] pl-10 sm:pl-12 pr-9 sm:pr-11 text-primary text-sm font-semibold focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/8 transition-all placeholder:text-primary/25 shadow-sm`} 
        />
        {loading && (
          <div className="absolute left-2 sm:left-3.5 top-1/2 -translate-y-1/2">
            <div className="w-3.5 h-3.5 border-2 border-primary/15 border-t-primary rounded-full animate-spin" />
          </div>
        )}
        {!loading && error && (
          <div className="absolute left-2 sm:left-3.5 top-1/2 -translate-y-1/2 text-amber-500">
            <AlertTriangle size={14} />
          </div>
        )}
      </div>
      {error && <p className="text-[10px] sm:text-[11px] font-bold text-amber-600 mt-1 sm:mt-1.5 mr-1 sm:mr-1.5">{error}</p>}
    </div>
  );
}
