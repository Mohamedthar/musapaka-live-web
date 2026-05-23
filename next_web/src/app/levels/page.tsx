'use client';

import React, { useEffect, useState } from 'react';
import { 
  Trophy, BookOpen, Sparkles, Users, ArrowLeft, ArrowRight, ShieldCheck, CheckCircle, MapPin, Phone, UserPlus
} from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';
import Header from '@/components/Header';
import { motion } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import type { CompetitionLevel } from '@/lib/database.types';

export default function LevelsPage() {
  const [levels, setLevels] = useState<CompetitionLevel[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchLevels = async () => {
      try {
        const { data } = await supabase
          .from('competition_levels')
          .select('*')
          .eq('is_active', true)
          .order('level_code');
        
        if (data) setLevels(data);
      } catch (err) {
        console.error('Error fetching levels:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchLevels();
  }, []);

  const generalPrizes = [
    {
      title: 'جوائز مالية كبرى للأوائل',
      desc: 'يحصل الحائزون على المراكز الأولى في كل فرع من فروع الحفظ على جوائز مالية كبرى تشجيعاً لهم.'
    },
    {
      title: 'دروع التميز التذكارية',
      desc: 'يُكرم المتسابقون الأوائل بدروع فاخرة تحمل شعار المسابقة ودرجة التميز في الحفل الختامي.'
    },
    {
      title: 'شهادات تقدير معتمدة',
      desc: 'تمنح اللجنة المنظمة شهادات تقدير موقعة ومعتمدة من لجان التحكيم لجميع من اجتازوا الاختبار بنجاح.'
    }
  ];

  return (
    <div className="min-h-screen bg-white flex flex-col font-cairo overflow-x-hidden" dir="rtl">
      <Header />

      {/* ─── PAGE HEADER ─── */}
      <section className="bg-[var(--bg-section)] py-12 px-4 text-center">
        <div className="max-w-4xl mx-auto">
          <div className="badge mb-4 inline-flex">
            <BookOpen size={12} />
            <span>الدليل التفصيلي للمسابقة</span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black text-[var(--primary)] mb-3">
            المستويات والجوائز
          </h1>
          <div className="divider-beige mb-4" />
          <p className="text-[var(--text-secondary)] text-xs sm:text-sm max-w-lg mx-auto leading-relaxed font-semibold">
            استعرض فروع مسابقة القرآن الكريم، الشروط العمرية المحددة لكل مستوى، وهيكل الجوائز والتكريم المخصص لحفظة كتاب الله.
          </p>
        </div>
      </section>

      {/* ─── MAIN CONTENT ─── */}
      <main className="max-w-5xl mx-auto px-4 py-16 w-full flex-1">
        
        {/* SECTION 1: Levels */}
        <section className="mb-20">
          <div className="text-center md:text-right mb-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h2 className="text-xl sm:text-2xl font-black text-[var(--primary)] flex items-center justify-center md:justify-start gap-2">
                <BookOpen size={22} className="text-[var(--beige-dark)]" />
                <span>فروع حفظ القرآن الكريم المعتمدة</span>
              </h2>
              <p className="text-[var(--text-muted)] text-xs font-semibold mt-1">تأكد من مطابقة شروط السن الخاصة بكل مستوى قبل البدء بالتسجيل الإلكتروني.</p>
            </div>
            
            <Link 
              href="/register" 
              className="inline-flex items-center justify-center gap-1.5 px-5 py-2.5 btn-primary text-xs font-bold self-center md:self-auto"
            >
              <span>انتقل للتسجيل المباشر</span>
              <ArrowLeft size={14} />
            </Link>
          </div>

          {loading ? (
            <div className="flex flex-col items-center justify-center py-20">
              <div className="w-8 h-8 border-3 border-[var(--beige)]/25 border-t-[var(--primary)] rounded-full animate-spin mb-3"></div>
              <span className="text-xs font-bold text-[var(--text-muted)]">جاري تحميل فروع المسابقة...</span>
            </div>
          ) : levels.length === 0 ? (
            <div className="text-center py-16 bg-[var(--bg-section)] rounded-2xl max-w-xl mx-auto">
              <p className="text-[var(--text-muted)] font-bold text-xs">لا تتوفر مستويات نشطة حالياً. يرجى مراجعة اللجنة المنظمة.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {levels.map((level, i) => (
                <div 
                  key={level.id ?? i}
                  className="card-elevated flex flex-col h-full overflow-hidden"
                >
                  {/* Card Header (Emerald) */}
                  <div className="bg-[var(--primary)] px-5 py-3.5 flex items-center justify-between">
                    <span className="text-[10px] font-black text-white bg-white/10 px-2.5 py-1 rounded-md">
                      {level.title}
                    </span>
                    {level.max_capacity && (
                      <span className="text-[9px] font-bold text-[var(--beige)]">
                        المقاعد المتاحة: {level.max_capacity} متسابق
                      </span>
                    )}
                  </div>
                  
                  <div className="p-6 flex-1 flex flex-col">
                    <h3 className="text-base sm:text-lg font-black text-[var(--primary)] mb-3 leading-snug">{level.content}</h3>
                    
                    {(level.min_age || level.max_age) && (
                      <div className="flex items-center gap-2 text-xs font-bold text-[var(--text-secondary)] mb-4">
                        <Users size={13} className="text-[var(--beige-dark)]" />
                        <span>
                          العمر المطلوب: {level.min_age ? `من ${level.min_age}` : ''} {level.min_age && level.max_age ? 'إلى' : ''} {level.max_age ? `${level.max_age} سنة` : ''}
                        </span>
                      </div>
                    )}

                    {level.notes && (
                      <div className="bg-[var(--beige-light)] p-3.5 rounded-xl mt-auto">
                        <h4 className="text-[9px] font-bold text-[var(--beige-dark)] mb-1 uppercase tracking-wider">ملاحظات الفرع</h4>
                        <p className="text-[11px] font-bold text-[var(--text-secondary)] leading-relaxed">
                          {level.notes}
                        </p>
                      </div>
                    )}
                  </div>

                  <div className="px-6 pb-6 pt-1">
                    <Link 
                      href="/register" 
                      className="flex items-center justify-center gap-2 w-full py-2.5 rounded-xl text-xs font-bold border-2 border-[var(--border)] text-[var(--text-primary)] hover:border-[var(--beige)] hover:bg-[var(--beige-light)] transition-all duration-200 group"
                    >
                      <span>اشترك في هذا الفرع</span>
                      <ArrowLeft size={13} className="group-hover:-translate-x-1 transition-transform" />
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>

        {/* SECTION 2: Prizes */}
        <section className="bg-[var(--bg-section)] rounded-2xl p-6 sm:p-10">
          <div className="text-center max-w-xl mx-auto mb-10">
            <div className="badge mb-3 inline-flex">
              <Trophy size={11} />
              <span>جوائز وتكريم المتفوقين</span>
            </div>
            <h2 className="text-xl sm:text-2xl font-black text-[var(--primary)]">هيكل التكريم والاحتفال الختامي</h2>
            <div className="divider-beige mb-3" />
            <p className="text-[var(--text-muted)] text-xs font-semibold leading-relaxed">
              تحرص اللجنة المنظمة على تقديم تكريم مميز يليق بمنزلة ومكانة متسابقي مسابقة القرآن الكريم بالحيدامون والديدامون.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {generalPrizes.map((prize, i) => (
              <div 
                key={i} 
                className="card-elevated p-5 flex flex-col items-center text-center"
              >
                <div className="w-10 h-10 rounded-full bg-[var(--primary)] flex items-center justify-center text-[var(--beige)] mb-4">
                  <Trophy size={18} />
                </div>
                <h3 className="text-sm sm:text-base font-extrabold text-[var(--primary)] mb-2">{prize.title}</h3>
                <p className="text-xs text-[var(--text-secondary)] leading-relaxed font-semibold">{prize.desc}</p>
              </div>
            ))}
          </div>
          
          <div className="mt-8 pt-6 border-t border-[var(--border)] flex flex-col sm:flex-row justify-between items-center gap-4 text-center sm:text-right bg-white/50 -mx-6 -mb-6 sm:-mx-10 sm:-mb-10 p-5 sm:px-8 rounded-b-2xl">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-[var(--primary)] flex items-center justify-center text-white"><ShieldCheck size={16} /></div>
              <span className="text-[10px] sm:text-xs font-black text-[var(--primary)]">معايير عادلة للجميع تحت إشراف مشايخ وقراء معتمدين</span>
            </div>
            <Link 
              href="/register" 
              className="px-5 py-2 btn-primary text-xs font-bold shadow-sm"
            >
              سجل للمنافسة الآن
            </Link>
          </div>
        </section>

      </main>

      {/* ─── FOOTER ─── */}
      <footer className="bg-[#111111] pt-16 pb-8 px-4 text-slate-300 relative">
        <div className="absolute inset-0 opacity-[0.03]">
          <div className="absolute top-0 left-1/4 w-64 h-64 bg-[var(--beige)] rounded-full blur-3xl" />
        </div>
        <div className="max-w-4xl mx-auto relative z-10">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-10 mb-12">
            <div>
              <h2 className="text-xl font-black text-white mb-4">اللجنة المنظمة للمسابقة</h2>
              <p className="text-slate-400 text-xs sm:text-sm leading-relaxed mb-6 font-semibold">
                يسعدنا الرد على استفساراتكم المتعلقة بالتسجيل الإلكتروني أو شروط مستويات وفروع الحفظ ومواعيد الاختبارات المجدولة.
              </p>

              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <span className="w-9 h-9 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center text-[var(--beige)]"><MapPin size={16} /></span>
                  <div>
                    <h4 className="text-[9px] font-bold text-slate-400">مقر الاختبارات والتصفيات</h4>
                    <p className="text-xs font-bold text-white">الديدامون والحيدامون — مركز فاقوس — محافظة الشرقية</p>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <span className="w-9 h-9 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center text-[var(--beige)]"><Phone size={16} /></span>
                  <div>
                    <h4 className="text-[9px] font-bold text-slate-400">الدعم الفني واللجنة المنظمة</h4>
                    <p className="text-xs font-bold text-white" dir="ltr">+20 100 123 4567</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-white/5 rounded-2xl p-6 border border-white/10 text-center flex flex-col justify-center items-center">
              <Trophy size={32} className="text-[var(--beige)] mb-4" />
              <h3 className="text-lg font-black text-white mb-2">حفل التكريم الختامي</h3>
              <p className="text-slate-400 text-xs leading-relaxed max-w-xs mb-6 font-semibold">
                تكريم سنوي بهيج لحفظة كتاب الله وتوزيع شهادات تقدير ودروع تميز وجوائز قيمة وسط كوكبة من المشايخ والعلماء.
              </p>
              <Link href="/register" className="inline-flex items-center gap-2 px-6 py-2.5 bg-[var(--beige)] hover:bg-[var(--beige-dark)] text-[#111111] font-bold text-xs rounded-xl transition-all">
                <UserPlus size={14} /> 
                <span>تسجيل متسابق جديد</span>
              </Link>
            </div>
          </div>
          
          <div className="border-t border-white/10 pt-6 flex flex-col sm:flex-row justify-between items-center gap-4 text-center sm:text-right">
            <div className="flex flex-col gap-1">
              <div className="flex items-center justify-center sm:justify-start gap-2 text-white font-extrabold text-sm">
                <span className="w-6 h-6 rounded-full overflow-hidden flex-shrink-0 border border-white/20">
                  <Image src="/logo_musapaka.jpeg" alt="" width={24} height={24} className="object-cover w-full h-full" />
                </span>
                <span>مسابقة أهل القرآن بالديدامون والحيدامون</span>
              </div>
              <p className="text-[10px] font-semibold text-slate-500">
                &copy; {new Date().getFullYear()} — جميع الحقوق محفوظة للجنة المنظمة للمسابقة.
              </p>
            </div>
            <div className="text-[10px] font-black text-[var(--beige-dark)] bg-white/5 px-3.5 py-2 rounded-lg border border-white/10 shadow-sm">
              إشراف وتنظيم: أ/ مصطفى عبدالرحمن محمد سالم
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
