'use client';

import React from 'react';
import Image from 'next/image';
import { 
  UserPlus, MapPin, Phone, 
  Trophy, Sparkles,
  BookOpen, ShieldCheck, Users, ArrowLeft, CheckCircle, Calendar, ClipboardCheck, Award, Gem
} from 'lucide-react';
import Link from 'next/link';
import Header from '@/components/Header';
import { motion } from 'framer-motion';

const staggerContainer = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { staggerChildren: 0.08 } }
} as const;

const fadeUp = {
  hidden: { opacity: 0, y: 15 },
  show: { opacity: 1, y: 0, transition: { type: 'spring' as const, stiffness: 100, damping: 22 } }
} as const;

export default function Home() {
  const features = [
    {
      icon: <Trophy size={22} />,
      title: 'تكريم وجوائز قيمة',
      desc: 'دروع تقديرية متألقة وجوائز مالية محفزة لجميع المتسابقين الأوائل في كافة الفروع.'
    },
    {
      icon: <ShieldCheck size={22} />,
      title: 'تحكيم مهني متخصص',
      desc: 'لجان تقييم عادلة ودقيقة بمشاركة نخبة من مشايخ وقراء كتاب الله الكريم.'
    },
    {
      icon: <Users size={22} />,
      title: 'فئات تناسب الجميع',
      desc: 'مستويات متعددة تبدأ من جزء واحد للبراعم الصغار وصولاً للقرآن كاملاً.'
    },
    {
      icon: <Gem size={22} />,
      title: 'بوابة إلكترونية متكاملة',
      desc: 'سهولة تامة في التسجيل، مع استعلام فوري عن مواعيد الاختبار والنتائج والشهادات.'
    }
  ];

  const journeySteps = [
    {
      icon: <ClipboardCheck size={20} />,
      title: '1. التسجيل الإلكتروني',
      desc: 'تعبئة استمارة الاشتراك وتحديد مستوى الحفظ المناسب بدقة تامة مع رفع صورتك الشخصية وشهادة الميلاد.'
    },
    {
      icon: <Calendar size={20} />,
      title: '2. حجز موعد الاختبار',
      desc: 'بعد تأكيد البيانات، سيتم تحديد يوم وساعة الاختبار الخاص بك تلقائياً ليظهر في بوابة استعلام الاستمارة.'
    },
    {
      icon: <Users size={20} />,
      title: '3. تأدية الاختبار',
      desc: 'الحضور في الموعد المحدد للوقوف أمام لجان التحكيم المتخصصة في مقر التصفيات بالديدامون والحيدامون.'
    },
    {
      icon: <Award size={20} />,
      title: '4. استعلام النتيجة',
      desc: 'متابعة بوابتك الإلكترونية لاستعراض درجات الفروع والتقدير العام فور اعتماد النتائج رسمياً.'
    },
    {
      icon: <Trophy size={20} />,
      title: '5. حفل التكريم الختامي',
      desc: 'تتويج مهيب للفائزين بالمراكز الأولى وتوزيع الجوائز النقدية الكبرى والدروع التقديرية التذكارية.'
    }
  ];

  return (
    <div className="min-h-screen bg-white flex flex-col font-cairo overflow-x-hidden" dir="rtl">
      <Header />

      {/* ─── HERO SECTION (Clean White + Beige) ─── */}
      <section className="relative flex flex-col items-center justify-center px-4 pt-20 pb-28 bg-gradient-to-b from-white via-white to-[var(--beige-light)] overflow-hidden">
        <div className="absolute inset-0 opacity-[0.15]">
          <div className="absolute top-10 left-10 w-72 h-72 bg-[var(--beige)] rounded-full blur-3xl" />
          <div className="absolute bottom-10 right-10 w-96 h-96 bg-[var(--beige)] rounded-full blur-3xl" />
        </div>
        <motion.div 
          variants={staggerContainer}
          initial="hidden"
          animate="show"
          className="max-w-4xl mx-auto text-center relative z-10 w-full mt-4 flex flex-col items-center"
        >
          <motion.div 
            variants={fadeUp} 
            className="badge mb-6"
          >
            <Sparkles size={12} />
            <span>مسابقة القرآن الكريم السنوية الكبرى بالديدامون</span>
          </motion.div>
          
          <motion.h1 
            variants={fadeUp} 
            className="text-4xl sm:text-5xl lg:text-6xl font-black mb-6 leading-tight tracking-tight text-[var(--text-primary)]"
          >
            مسابقة أهل <span className="text-[var(--beige-dark)]">القرآن</span> الكبرى
          </motion.h1>
          
          <motion.p 
            variants={fadeUp} 
            className="text-sm sm:text-base text-[var(--text-secondary)] mb-10 max-w-xl mx-auto leading-relaxed font-semibold"
          >
            بوابة التسجيل والاستعلام الإلكتروني الموحدة لمنافسات حفظ وتلاوة كتاب الله عز وجل، بمشاركة وتكريم حفظة القرآن بمختلف الأعمار.
          </motion.p>

          <motion.div 
            variants={fadeUp} 
            className="flex flex-col sm:flex-row items-center justify-center gap-3 w-full sm:w-auto px-4 sm:px-0"
          >
            <Link 
              href="/register" 
              className="w-full sm:w-auto flex justify-center items-center gap-2 px-7 py-3.5 btn-primary text-sm font-bold shadow-sm"
            >
              <UserPlus size={16} />
              <span>ابدأ تسجيلك الآن</span>
            </Link>
            
            <Link 
              href="/levels" 
              className="w-full sm:w-auto flex justify-center items-center gap-2 px-7 py-3.5 btn-outline text-sm font-bold"
            >
              <BookOpen size={16} />
              <span>عرض فروع وجوائز المسابقة</span>
            </Link>
          </motion.div>
        </motion.div>
      </section>

      {/* ─── QUICK STATS BAR ─── */}
      <section className="relative -mt-8 z-20 px-4 max-w-4xl mx-auto w-full">
        <div className="card-elevated p-5 grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="flex items-center gap-3 px-3 py-1 justify-center sm:justify-start">
            <div className="w-10 h-10 rounded-xl bg-[var(--beige-light)] flex items-center justify-center text-[var(--beige-dark)] flex-shrink-0">
              <BookOpen size={20} />
            </div>
            <div>
              <h4 className="text-[10px] font-bold text-[var(--text-muted)]">مستويات الحفظ</h4>
              <p className="text-xs font-black text-[var(--primary)]">فروع تنافسية متعددة</p>
            </div>
          </div>
          
          <div className="flex items-center gap-3 px-3 py-1 justify-center">
            <div className="w-10 h-10 rounded-xl bg-[var(--beige-light)] flex items-center justify-center text-[var(--beige-dark)] flex-shrink-0">
              <Trophy size={20} />
            </div>
            <div>
              <h4 className="text-[10px] font-bold text-[var(--text-muted)]">حفل التكريم</h4>
              <p className="text-xs font-black text-[var(--primary)]">جوائز مالية قيمة للأوائل</p>
            </div>
          </div>

          <div className="flex items-center gap-3 px-3 py-1 justify-center sm:justify-end">
            <div className="w-10 h-10 rounded-xl bg-[var(--beige-light)] flex items-center justify-center text-[var(--beige-dark)] flex-shrink-0">
              <CheckCircle size={20} />
            </div>
            <div>
              <h4 className="text-[10px] font-bold text-[var(--text-muted)]">معايير الاختبار</h4>
              <p className="text-xs font-black text-[var(--primary)]">تقييم دقيق وشفاف</p>
            </div>
          </div>
        </div>
      </section>

      {/* ─── FEATURES SECTION ─── */}
      <section className="py-20 px-4 bg-white relative">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-14">
            <div className="badge mb-3 inline-flex">
              <span>مزايا المسابقة</span>
            </div>
            <h2 className="text-2xl sm:text-3xl font-black text-[var(--primary)]">خدمات متميزة لحفظة القرآن</h2>
            <div className="divider-beige" />
            <p className="text-[var(--text-muted)] max-w-lg mx-auto text-xs sm:text-sm mt-3 font-semibold">
              نوظف الوسائل التقنية الحديثة لضمان تجربة تسجيل واستعلام سلسلة وعادلة تليق بالمتسابقين.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 max-w-4xl mx-auto">
            {features.map((feat, i) => (
              <motion.div 
                key={i}
                initial={{ opacity: 0, y: 15 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.06 }}
                className="card-elevated p-6 flex gap-4 items-start"
              >
                <div className="w-11 h-11 rounded-xl bg-[var(--primary)] flex items-center justify-center text-[var(--beige)] flex-shrink-0">
                  {feat.icon}
                </div>
                <div className="text-right">
                  <h3 className="text-base font-extrabold text-[var(--primary)] mb-1">{feat.title}</h3>
                  <p className="text-xs font-semibold text-[var(--text-secondary)] leading-relaxed">{feat.desc}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── JOURNEY TIMELINE SECTION ─── */}
      <section className="py-20 px-4 bg-[var(--bg-section)] relative">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-14">
            <div className="badge mb-3 inline-flex">
              <span>رحلة المتسابق</span>
            </div>
            <h2 className="text-2xl sm:text-3xl font-black text-[var(--primary)]">خطوات المشاركة والجدول الزمني للرحلة</h2>
            <div className="divider-beige" />
            <p className="text-[var(--text-muted)] max-w-lg mx-auto text-xs sm:text-sm mt-3 font-semibold">
              تعرف على المراحل الخمس لرحلة المتسابق منذ التسجيل الإلكتروني الأول وحتى تتويجه في الحفل الختامي.
            </p>
          </div>

          <div className="max-w-3xl mx-auto space-y-6">
            {journeySteps.map((step, i) => (
              <motion.div 
                key={i}
                initial={{ opacity: 0, x: -10 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.06 }}
                className="card-elevated p-5 sm:p-6 flex gap-4 items-start"
              >
                <div className="w-10 h-10 rounded-xl bg-[var(--primary)] flex items-center justify-center text-[var(--beige)] flex-shrink-0">
                  {step.icon}
                </div>
                <div className="text-right flex-1">
                  <h3 className="text-sm sm:text-base font-extrabold text-[var(--primary)] mb-1">{step.title}</h3>
                  <p className="text-xs sm:text-xs text-[var(--text-secondary)] leading-relaxed font-semibold">{step.desc}</p>
                </div>
              </motion.div>
            ))}
          </div>
          
          <div className="text-center mt-12">
            <Link 
              href="/register" 
              className="inline-flex items-center gap-2 px-8 py-3.5 btn-primary text-xs font-bold shadow-sm"
            >
              <span>ابدأ رحلتك القرآنية وسجل الآن</span>
              <ArrowLeft size={14} />
            </Link>
          </div>
        </div>
      </section>

      {/* ─── FOOTER (Black BG) ─── */}
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
