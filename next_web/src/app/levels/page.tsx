'use client';

import React, { useEffect, useState } from 'react';
import {
  Trophy, BookOpen, Users, ArrowLeft, Award, Sparkles
} from 'lucide-react';
import Link from 'next/link';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import { motion } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import type { CompetitionLevel } from '@/lib/database.types';

const prizeIcons = [Trophy, Award, Award];
const prizeColors = ['text-[#D4AF37]', 'text-[#A0A0A0]', 'text-[#CD7F32]'];
const prizeLabels = ['الجائزة الأولى', 'الجائزة الثانية', 'الجائزة الثالثة'];

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

  return (
    <div className="min-h-screen bg-surface flex flex-col font-cairo overflow-x-hidden" dir="rtl">
      <Header />

      {/* ─── PAGE HEADER ─── */}
      <section className="relative bg-gradient-to-b from-primary via-primary/95 to-primary-container pt-16 pb-20 px-4 overflow-hidden">
        <div className="absolute inset-0 islamic-pattern z-0 opacity-[0.04]" />
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-secondary-fixed/10 rounded-full blur-[120px] z-0" />

        <div className="relative z-10 max-w-4xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="inline-flex items-center gap-1.5 bg-white/10 text-secondary-fixed text-[10px] font-black px-3 py-1.5 rounded-full mb-5"
          >
            <BookOpen size={11} />
            <span>الدليل التفصيلي للمسابقة</span>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.08 }}
            className="text-3xl sm:text-4xl lg:text-5xl font-black text-secondary-fixed mb-4"
            style={{ fontFamily: "'Noto Serif', serif" }}
          >
            المستويات والجوائز
          </motion.h1>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.14 }}
            className="w-16 h-1 bg-secondary-fixed/50 mx-auto rounded-full mb-4"
          />

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="text-white/70 text-xs sm:text-sm max-w-xl mx-auto leading-relaxed font-semibold"
          >
            استعرض فروع المسابقة، الشروط العمرية، وهيكل الجوائز المخصصة لحفظة كتاب الله.
          </motion.p>
        </div>
      </section>

      {/* ─── MAIN CONTENT ─── */}
      <main className="max-w-5xl mx-auto px-4 w-full flex-1 -mt-10 relative z-20">

        {/* SECTION 1: Levels */}
        <section className="mb-20">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
            <div>
              <h2 className="text-xl sm:text-2xl font-black text-primary flex items-center gap-2">
                <BookOpen size={20} className="text-secondary" />
                <span>فروع الحفظ المعتمدة</span>
              </h2>
              <p className="text-on-surface-variant text-xs font-semibold mt-1">
                اختر المستوى المناسب لقدراتك وتأكد من مطابقة الشروط
              </p>
            </div>

            <Link
              href="/register"
              className="inline-flex items-center justify-center gap-1.5 px-5 py-2.5 bg-primary text-on-primary rounded-xl text-xs font-bold hover:bg-primary-container active:scale-95 transition-all self-center md:self-auto shrink-0"
            >
              <span>انتقل للتسجيل</span>
              <ArrowLeft size={14} />
            </Link>
          </div>

          {loading ? (
            <div className="flex flex-col items-center justify-center py-20">
              <div className="w-8 h-8 border-[3px] border-secondary/25 border-t-primary rounded-full animate-spin mb-3" />
              <span className="text-xs font-bold text-on-surface-variant">جاري التحميل...</span>
            </div>
          ) : levels.length === 0 ? (
            <div className="text-center py-16 bg-surface-container-low rounded-2xl max-w-xl mx-auto">
              <p className="text-on-surface-variant font-bold text-xs">لا تتوفر مستويات نشطة حالياً.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {levels.map((level, i) => {
                const hasPrizesText = !!level.prizes;
                const hasIndividualPrizes = level.first_prize || level.second_prize || level.third_prize;
                const individualPrizes = [level.first_prize, level.second_prize, level.third_prize];

                const prizesBlock = hasPrizesText ? (
                  <div className="bg-gradient-to-br from-secondary-fixed/15 to-secondary-fixed/5 rounded-xl p-3.5">
                    <div className="flex items-center gap-1.5 text-[10px] font-black text-secondary mb-2">
                      <Trophy size={12} />
                      <span>الجوائز</span>
                    </div>
                    <p className="text-[11px] font-bold text-on-surface leading-relaxed">
                      {level.prizes}
                    </p>
                  </div>
                ) : hasIndividualPrizes ? (
                  <div className="bg-gradient-to-br from-secondary-fixed/15 to-secondary-fixed/5 rounded-xl p-3.5 space-y-2">
                    <div className="flex items-center gap-1.5 text-[10px] font-black text-secondary mb-2">
                      <Trophy size={12} />
                      <span>الجوائز</span>
                    </div>
                    {individualPrizes.map((prize, pi) => {
                      const Icon = prizeIcons[pi];
                      if (!prize) return null;
                      return (
                        <div key={pi} className="flex items-start gap-2.5">
                          <Icon size={13} className={`${prizeColors[pi]} mt-0.5 shrink-0`} />
                          <div>
                            <span className="text-[9px] font-black text-on-surface-variant/60">{prizeLabels[pi]}: </span>
                            <span className="text-[11px] font-bold text-on-surface">{prize}</span>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : null;

                return (
                  <motion.div
                    key={level.id ?? i}
                    initial={{ opacity: 0, y: 24 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.06, ease: [0.25, 0.46, 0.45, 0.94] }}
                    className="bg-white rounded-2xl border border-outline-variant/20 hover:shadow-lg hover:border-secondary/30 transition-all duration-300 flex flex-col overflow-hidden group"
                  >
                    {/* Card Header */}
                    <div className="relative bg-gradient-to-l from-primary to-primary/90 px-5 py-4 flex items-center justify-between gap-3">
                      {/* Level Code Badge */}
                      <div className="flex items-center gap-2.5">
                        <div className="w-9 h-9 rounded-xl bg-secondary-fixed/20 text-secondary-fixed flex items-center justify-center text-sm font-black">
                          {level.level_code}
                        </div>
                        <span className="text-[11px] font-black text-white/90">
                          {level.title}
                        </span>
                      </div>

                      {level.max_capacity && (
                        <span className="text-[9px] font-bold text-secondary-fixed/80 bg-white/5 px-2.5 py-1 rounded-md">
                          <Users size={9} className="inline ml-1 -mt-0.5" />
                          {level.max_capacity} مقعد
                        </span>
                      )}
                    </div>

                    <div className="p-5 flex-1 flex flex-col gap-4">
                      {/* Description */}
                      <h3 className="text-sm sm:text-base font-black text-primary leading-relaxed">
                        {level.content}
                      </h3>

                      {/* Age */}
                      {(level.min_age || level.max_age) && (
                        <div className="flex items-center gap-2 text-[11px] font-bold text-on-surface-variant bg-surface-container-low py-2 px-3 rounded-xl">
                          <Users size={13} className="text-secondary shrink-0" />
                          <span>
                            العمر المطلوب:
                            {level.min_age ? ` فوق ${level.min_age}` : ''}
                            {level.min_age && level.max_age ? ' عام و' : ''}
                            {level.max_age ? ` ${level.max_age} عام فأقل` : ''}
                            {!level.min_age && !level.max_age ? ' جميع الأعمار' : ''}
                          </span>
                        </div>
                      )}

                      {/* Prizes */}
                      {prizesBlock}

                      {/* Notes */}
                      {level.notes && (
                        <div className="text-[11px] font-bold text-on-surface-variant bg-primary/5 p-3 rounded-xl leading-relaxed">
                          <span className="text-[9px] font-black text-primary block mb-1">ملاحظات</span>
                          {level.notes}
                        </div>
                      )}
                    </div>

                    {/* CTA */}
                    <div className="px-5 pb-5 pt-1">
                      <Link
                        href={`/register?level=${encodeURIComponent(level.title)}`}
                        className="flex items-center justify-center gap-2 w-full py-2.5 rounded-xl text-xs font-bold border-2 border-outline-variant/40 text-on-surface hover:border-secondary hover:bg-secondary-fixed/10 transition-all duration-200 group/btn"
                      >
                        <span>اشترك في هذا الفرع</span>
                        <ArrowLeft size={13} className="group-hover/btn:-translate-x-1 transition-transform" />
                      </Link>
                    </div>
                  </motion.div>
                );
              })}
            </div>
          )}
        </section>

        {/* SECTION 2: General Prizes Summary */}
        <section className="bg-gradient-to-br from-surface-container-low to-surface-container-low/80 rounded-2xl p-6 sm:p-10 mb-16 border border-outline-variant/10">
          <div className="text-center max-w-xl mx-auto mb-10">
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="inline-flex items-center gap-1.5 bg-primary/5 text-primary text-[10px] font-black px-3 py-1.5 rounded-full mb-3"
            >
              <Trophy size={11} />
              <span>جوائز وتكريم</span>
            </motion.div>
            <h2 className="text-xl sm:text-2xl font-black text-primary"
              style={{ fontFamily: "'Noto Serif', serif" }}>
              هيكل التكريم العام
            </h2>
            <div className="w-16 h-1 bg-secondary mx-auto rounded-full my-3" />
            <p className="text-on-surface-variant text-xs font-semibold leading-relaxed">
              جوائز وتكريمات يخصصها المنظمون للمتفوقين في ختام المسابقة
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {[
              { icon: Trophy, color: 'text-[#D4AF37]', title: 'جوائز مالية كبرى', desc: 'جوائز مالية قيمة للأوائل في كل فرع من فروع الحفظ.' },
              { icon: Trophy, color: 'text-secondary', title: 'دروع تميز', desc: 'دروع فاخرة تحمل شعار المسابقة تُمنح للمتفوقين في الحفل الختامي.' },
              { icon: Sparkles, color: 'text-primary', title: 'شهادات معتمدة', desc: 'شهادات تقدير موقعة من لجان التحكيم للمجتازين.' },
            ].map((item, i) => {
              const Icon = item.icon;
              return (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.06 }}
                  className="bg-white rounded-2xl border border-outline-variant/20 p-5 flex flex-col items-center text-center hover:shadow-md hover:border-secondary/20 transition-all duration-300"
                >
                  <div className={`w-11 h-11 rounded-full bg-primary/5 flex items-center justify-center mb-4 ${item.color}`}>
                    <Icon size={20} />
                  </div>
                  <h3 className="text-sm font-black text-primary mb-2">{item.title}</h3>
                  <p className="text-[11px] text-on-surface-variant leading-relaxed font-semibold">{item.desc}</p>
                </motion.div>
              );
            })}
          </div>

          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="mt-8 pt-5 border-t border-outline-variant/20 flex flex-col sm:flex-row items-center justify-between gap-4"
          >
            <div className="flex items-center gap-2.5 text-[11px] font-bold text-on-surface-variant">
              <div className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center text-secondary-fixed">
                <ShieldCheck size={14} />
              </div>
              <span>معايير عادلة تحت إشراف مشايخ وقراء معتمدين</span>
            </div>
            <Link
              href="/register"
              className="px-5 py-2 bg-primary text-on-primary rounded-xl text-xs font-bold hover:bg-primary-container active:scale-95 transition-all shadow-sm shrink-0"
            >
              سجل الآن
            </Link>
          </motion.div>
        </section>

      </main>

      <Footer />
    </div>
  );
}

function ShieldCheck({ size }: { size?: number }) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width={size ?? 24} height={size ?? 24} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z" />
      <path d="m9 12 2 2 4-4" />
    </svg>
  );
}
