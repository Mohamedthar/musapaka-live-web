'use client';

import React, { useState, useRef, useEffect } from 'react';
import { CreditCard, Hash, CalendarCheck, User, Layers, Printer, Download, Search, MapPin } from 'lucide-react';
import toast from 'react-hot-toast';
import ClosedState from '@/components/ClosedState';

interface CeremonyData {
  name: string; gender: string; level: string; level_content: string;
  ceremony_code: string; profile_image_url: string | null; is_eligible: boolean;
}

export default function CeremonyInquiry() {
  const [nationalId, setNationalId] = useState('');
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [data, setData] = useState<CeremonyData | null>(null);
  const [checkingStatus, setCheckingStatus] = useState(true);
  const [isOpen, setIsOpen] = useState<boolean | null>(null);
  const [isDownloading, setIsDownloading] = useState(false);
  const ticketRef = useRef<HTMLDivElement>(null);

  const idValid = nationalId.length === 14;

  useEffect(() => {
    fetch('/api/ceremony').then(r => r.json()).then(d => setIsOpen(d.is_ceremony_query_open)).catch(() => setIsOpen(false)).finally(() => setCheckingStatus(false));
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idValid) { setError('الرقم القومي يجب أن يتكون من 14 رقماً'); return; }
    setError(''); setLoading(true); setSearched(true); setData(null);
    try {
      const r = await fetch('/api/ceremony', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ nationalId }) });
      const d = await r.json();
      if (!r.ok) { setError(d.error || 'حدث خطأ'); return; }
      setData(d.student);
    } catch { setError('فشل الاتصال بالخادم'); }
    finally { setLoading(false); }
  };

  const handleReset = () => { setData(null); setSearched(false); setError(''); setNationalId(''); };

  const downloadImage = async () => {
    setIsDownloading(true);
    const tid = toast.loading('جاري تجهيز بطاقة الدعوة...');
    try {
      const html2canvas = (await import('html2canvas-pro')).default;
      const el = document.getElementById('ceremony-ticket');
      if (!el) { toast.error('لم يتم العثور على البطاقة', { id: tid }); return; }
      const canvas = await html2canvas(el, { scale: 2, useCORS: true, backgroundColor: '#fff', logging: false, windowWidth: 850, windowHeight: el.scrollHeight + 100 });
      const link = document.createElement('a');
      link.href = canvas.toDataURL('image/png');
      link.download = `دعوة_${data?.name?.replace(/\s+/g, '_') ?? 'طالب'}.png`;
      document.body.appendChild(link); link.click(); document.body.removeChild(link);
      toast.success('تم تحميل بطاقة الدعوة بنجاح', { id: tid });
    } catch { toast.error('فشل تحميل الصورة', { id: tid }); }
    finally { setIsDownloading(false); }
  };

  if (checkingStatus) {
    return <div className="flex items-center justify-center py-24"><div className="w-10 h-10 border-3 border-secondary/25 border-t-secondary rounded-full animate-spin" /></div>;
  }

  if (isOpen === false) return <ClosedState type="ceremony" />;

  // ── Result View ──
  if (data) {
    const eligibleColor = data.is_eligible ? 'text-emerald-600' : 'text-red-500';
    const eligibleBg = data.is_eligible ? 'bg-emerald-50 border-emerald-200' : 'bg-red-50 border-red-200';
    const eligibleText = data.is_eligible ? 'مؤهل للحضور' : 'غير مؤهل';

    return (
      <div className="w-full animate-fade-in" dir="rtl">
        {/* Actions */}
        <div className="flex items-center justify-between mb-8 print:hidden">
          <button onClick={handleReset} className="flex items-center gap-2 text-sm font-bold text-gray-400 hover:text-gray-600 transition-colors px-4 py-2 rounded-xl hover:bg-gray-50">
            <span>→</span> بحث جديد
          </button>
          {data.is_eligible && (
            <div className="flex gap-2">
              <button onClick={() => window.print()} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm font-bold transition-all">
                <Printer size={16} /> طباعة
              </button>
              <button onClick={downloadImage} disabled={isDownloading} className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-secondary hover:bg-secondary-fixed-dim text-white text-sm font-bold transition-all shadow-sm">
                <Download size={16} /> {isDownloading ? 'جاري...' : 'تحميل'}
              </button>
            </div>
          )}
        </div>

        {/* Card */}
        <div id="ceremony-ticket" className="bg-white rounded-3xl shadow-xl shadow-gray-100 overflow-hidden print:shadow-none print:rounded-none">
          <div className="h-3 bg-gradient-to-r from-secondary via-secondary-fixed to-secondary" />

          <div className="p-6 sm:p-12">
            {/* Header */}
            <div className="text-center mb-10">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-emerald-50 mb-3">
                <CalendarCheck size={28} className="text-emerald-500" />
              </div>
              <h2 className="text-2xl font-black text-gray-900">بطاقة دعوة حفل التكريم</h2>
              <p className="text-sm text-gray-400 mt-1">مسابقة القرآن الكريم</p>
            </div>

            {/* Profile image */}
            {data.profile_image_url && (
              <div className="flex justify-center mb-8">
                <div className="w-24 h-24 rounded-full overflow-hidden border-4 border-emerald-100 shadow-sm">
                  <img src={data.profile_image_url} alt={data.name} className="w-full h-full object-cover" />
                </div>
              </div>
            )}

            {/* Student info */}
            <div className="grid grid-cols-2 gap-3 sm:gap-4 mb-8">
              {[
                { label: 'الاسم', value: data.name, icon: <User size={14} /> },
                { label: 'المستوى', value: data.level_content ? `${data.level} - ${data.level_content}` : data.level, icon: <Layers size={14} /> },
                { label: 'كود الحضور', value: data.ceremony_code, icon: <Hash size={14} /> },
                { label: 'النوع', value: data.gender === 'M' || data.gender === 'ذكر' ? 'ذكر' : 'أنثى', icon: <User size={14} /> },
              ].map((item, i) => (
                <div key={i} className="bg-gray-50 rounded-2xl p-4 border border-gray-100">
                  <div className="flex items-center gap-1.5 text-gray-400 mb-1">{item.icon}<span className="text-xs font-bold">{item.label}</span></div>
                  <p className="text-sm font-bold text-gray-800">{item.value}</p>
                </div>
              ))}
            </div>

            {/* Eligibility */}
            <div className={`rounded-2xl p-5 border-2 text-center mb-8 ${eligibleBg}`}>
              <p className={`text-lg font-black ${eligibleColor}`}>{eligibleText}</p>
              {data.is_eligible && <p className="text-sm text-gray-500 mt-1">يسرنا دعوتكم لحضور حفل التكريم الختامي</p>}
            </div>

            {/* Congratulation */}
            {data.is_eligible && (
              <div className="bg-gray-50 rounded-2xl p-6 border border-gray-100 text-center mb-8">
                <p className="text-sm font-bold text-gray-700 leading-relaxed">
                  تهانينا القلبية لك! لقد اجتزت اختبارات المسابقة بتفوق. يسعدنا ويشرفنا حضورك حفل التكريم الختامي لتكريمك وتتويجك، سائلين المولى عز وجل أن يجعلك من أهل القرآن.
                </p>
              </div>
            )}

            {/* Supervisor */}
            <div className="text-center border-t border-gray-100 pt-6">
              <p className="text-xs font-bold text-gray-400">المشرف العام على المسابقة</p>
              <p className="text-base font-black text-gray-800 mt-1">أ/ مصطفى عبدالرحمن محمد سالم</p>
              <p className="text-xs text-gray-400 mt-2">مقر اللجنة: مركز فاقوس - قرية الديدمون - شارع الشيخ - منزل المشرف العام</p>
            </div>

            {/* Footer hint */}
            <div className="mt-6 flex items-center justify-center gap-2 text-xs text-gray-400">
              <MapPin size={12} />
              <span>يرجى إحضار هذه البطاقة يوم الحفل</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // ── Form View ──
  return (
    <div className="w-full">
      <div className="text-center mb-8">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-secondary/10 mb-4">
          <CalendarCheck size={28} className="text-secondary" />
        </div>
        <h1 className="text-xl sm:text-3xl font-black text-primary mb-2">استعلام حضور الحفل الختامي</h1>
        <p className="text-sm text-on-surface-variant max-w-md mx-auto leading-relaxed">
          أدخل الرقم القومي لمعرفة موقفك من حضور حفل التكريم واستخراج بطاقة الدعوة الخاصة بك
        </p>
      </div>

      <form onSubmit={handleSubmit} className="max-w-md mx-auto">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 sm:p-8 space-y-5 sm:space-y-6">
          <div>
            <label className="block text-sm font-bold text-gray-700 mb-2">الرقم القومي للمتسابق <span className="text-red-400">*</span></label>
            <div className="relative">
              <input type="text" inputMode="numeric" maxLength={14}
                value={nationalId} onChange={e => { setNationalId(e.target.value.replace(/\D/g, '')); setSearched(false); setError(''); }}
                placeholder="أدخل الـ 14 رقماً"
                className={`w-full bg-gray-50 border-2 rounded-2xl py-3.5 pr-12 pl-4 text-sm font-semibold transition-all outline-none
                  ${searched && !idValid ? 'border-red-200 bg-red-50/30' : 'border-gray-100 focus:border-secondary focus:bg-white focus:ring-4 focus:ring-secondary/5'}
                  text-gray-900 placeholder:text-gray-400`}
              />
              <CreditCard size={18} className={`absolute right-4 top-1/2 -translate-y-1/2 ${searched && !idValid ? 'text-red-400' : 'text-gray-400'}`} />
            </div>
            {searched && !idValid && <p className="text-red-500 text-xs font-bold mt-1.5 pr-1">الرقم القومي يجب أن يتكون من 14 رقماً</p>}
          </div>

          {error && <div className="bg-red-50 border border-red-100 rounded-2xl px-5 py-3.5"><p className="text-red-600 text-xs font-bold text-center">{error}</p></div>}

          <button type="submit" disabled={loading || !idValid}
            className="w-full flex items-center justify-center gap-2 sm:gap-2.5 py-3.5 sm:py-4 rounded-2xl font-bold text-white transition-all duration-300
              bg-gradient-to-r from-secondary to-secondary-fixed-dim hover:from-secondary-fixed-dim hover:to-secondary
              shadow-lg shadow-secondary/20 hover:shadow-xl hover:shadow-secondary/30 hover:-translate-y-0.5
              disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:translate-y-0">
            {loading ? <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : <><span>استخراج بطاقة الدعوة</span><Search size={18} /></>}
          </button>
        </div>
      </form>
      <p className="text-center text-xs text-gray-400 mt-6">يرجى إحضار البطاقة المطبوعة أو صورة منها يوم الحفل</p>
    </div>
  );
}
