'use client';

import React, { useEffect, useState } from 'react';
import { Trophy, BookOpen } from 'lucide-react';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
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

  return (
    <div className="min-h-screen bg-surface flex flex-col font-cairo overflow-x-hidden" dir="rtl">
      <Header />

      <div className="flex-1">
        {/* ─── HERO ─── */}
        <section className="relative min-h-[40vh] md:min-h-[45vh] flex items-center overflow-hidden bg-primary-container">
          <div className="absolute inset-0 islamic-pattern z-0 opacity-[0.5]" />

          <motion.div
            initial={{ opacity: 0, scale: 1.05 }}
            animate={{ opacity: 0.55, scale: 1 }}
            transition={{ duration: 2, ease: 'easeOut' }}
            className="absolute inset-0 z-[1]"
          >
            <div
              className="absolute inset-0 bg-cover bg-center"
              style={{
                backgroundImage: "url('/background.png')",
                backgroundPosition: 'center 40%',
              }}
            />
            <div className="absolute inset-0 bg-gradient-to-b from-black/20 via-transparent to-primary-container/50" />
          </motion.div>

          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1.5, ease: 'easeOut' }}
            className="absolute -top-32 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-secondary-fixed/8 rounded-full blur-[120px] pointer-events-none z-[2]"
          />

          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1.5, ease: 'easeOut', delay: 0.2 }}
            className="absolute -bottom-48 -right-48 w-[600px] h-[600px] bg-secondary-fixed/6 rounded-full blur-[150px] pointer-events-none z-[2]"
          />
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1.5, ease: 'easeOut', delay: 0.4 }}
            className="absolute -top-48 -left-48 w-[500px] h-[500px] bg-white/4 rounded-full blur-[150px] pointer-events-none z-[2]"
          />

          <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-primary-container/60 z-[3]" />

          <div className="absolute inset-x-0 bottom-0 h-32 bg-gradient-to-t from-surface to-transparent z-[4] pointer-events-none" />

          <div className="max-w-7xl mx-auto px-6 relative z-10 text-center w-full py-20">
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-primary text-white font-black text-xs mb-5 shadow-md shadow-primary/20"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-primary-fixed animate-pulse" />
              فروع المسابقة
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
              className="text-[32px] sm:text-[44px] md:text-[56px] font-black text-secondary-fixed leading-[1.2] mb-3"
              style={{
                fontFamily: "'Noto Serif', serif",
                textShadow: '0 0 40px rgba(255,224,136,0.4), 0 4px 8px rgba(0,0,0,0.5)',
              }}
            >
              المستويات وشروطها
            </motion.h1>

            <div className="flex items-center justify-center gap-2 mt-3 mb-6">
              <span className="w-8 h-0.5 rounded-full bg-secondary-fixed/30" />
              <span className="w-2 h-2 rounded-full bg-secondary-fixed/60" />
              <span className="w-8 h-0.5 rounded-full bg-secondary-fixed/30" />
            </div>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.5 }}
              className="text-white text-sm sm:text-base max-w-xl mx-auto leading-relaxed font-semibold"
              style={{ textShadow: '0 2px 8px rgba(0,0,0,0.5)' }}
            >
              تعرف على فروع المسابقة، الشروط العمرية، والجوائز المخصصة لكل مستوى
            </motion.p>
          </div>

          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.5, duration: 0.5 }}
            className="absolute bottom-6 left-1/2 -translate-x-1/2 animate-bounce z-10"
          >
            <span className="material-symbols-outlined text-secondary-fixed text-3xl">expand_more</span>
          </motion.div>
        </section>

        {/* ─── LEVELS GRID ─── */}
        <section className="relative py-16 bg-gradient-to-b from-surface via-surface to-surface-container-low overflow-hidden">
          <div className="absolute inset-0 islamic-pattern opacity-[0.03]" />
          <div className="max-w-7xl mx-auto px-6 relative z-10">
            {loading ? (
              <div className="flex flex-col items-center justify-center py-20">
                <div className="w-10 h-10 border-[3px] border-secondary/25 border-t-primary rounded-full animate-spin mb-4" />
                <span className="text-sm font-bold text-on-surface-variant">جاري تحميل المستويات...</span>
              </div>
            ) : levels.length === 0 ? (
              <div className="text-center py-16 bg-surface-container-low rounded-2xl border border-outline-variant/10">
                <BookOpen size={32} className="mx-auto text-on-surface-variant/30 mb-3" />
                <p className="text-on-surface-variant font-bold text-sm">
                  لا تتوفر مستويات نشطة حالياً
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-5 lg:gap-6">
                {levels.map((level, i) => {
                  const individualPrizes = [level.first_prize, level.second_prize, level.third_prize];
                  const hasIndividualPrizes = individualPrizes.some(Boolean);
                  const codeNum = String(level.level_code).replace(/\D/g, '');

                  return (
                    <motion.div
                      key={level.id ?? i}
                      initial={{ opacity: 0, y: 30 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.5, delay: i * 0.08, ease: 'easeOut' }}
                      whileHover={{ y: -4 }}
                      className="bg-white rounded-xl shadow-sm hover:shadow-md transition-all duration-300 flex flex-col overflow-hidden border border-outline-variant/10"
                    >
                      {/* Header */}
                      <div className="bg-primary px-3 lg:px-4 py-2.5 lg:py-3 flex items-center gap-2 lg:gap-2.5">
                        <span className="w-8 lg:w-10 h-8 lg:h-10 rounded-xl bg-secondary-fixed text-on-secondary-fixed flex items-center justify-center font-black text-xs lg:text-sm shrink-0 shadow-sm">
                          {codeNum || level.level_code}
                        </span>
                        <div className="flex-1 min-w-0 flex items-baseline gap-2">
                          <h3 className="text-white font-black text-xs lg:text-sm leading-tight">{level.title}</h3>
                        </div>
                        {(level.min_age || level.max_age) && (
                          <span className="text-[10px] lg:text-xs font-black text-secondary-fixed bg-white/10 px-2 lg:px-2.5 py-0.5 rounded-lg shrink-0">
                            {level.min_age ? `فوق ${level.min_age}` : ''}
                            {level.min_age && level.max_age ? ' - ' : ''}
                            {level.max_age ? `${level.max_age} فأقل` : ''}
                            {!level.min_age && !level.max_age ? 'جميع الأعمار' : ''}
                          </span>
                        )}
                        {level.max_capacity && (
                          <span className="text-[9px] lg:text-[10px] font-bold text-secondary-fixed/70 bg-white/8 px-2 lg:px-2.5 py-0.5 rounded shrink-0">
                            {level.max_capacity}
                          </span>
                        )}
                      </div>

                      {/* Content */}
                      <div className="p-4 lg:p-5 flex-1 flex flex-col gap-3 lg:gap-4">
                        <p className="text-xs lg:text-sm font-bold text-primary leading-relaxed">
                          {level.content}
                        </p>

                        {level.prizes && (
                          <div className="bg-gradient-to-br from-secondary-fixed/[0.04] to-transparent rounded-lg lg:rounded-xl p-3 lg:p-4 border border-secondary-fixed/10">
                            <div className="flex items-center gap-1.5 lg:gap-2 text-[11px] lg:text-xs font-black text-secondary mb-1.5">
                              <Trophy size={11} className="lg:w-3.5 lg:h-3.5" />
                              <span>الجوائز</span>
                            </div>
                            <p className="text-[11px] lg:text-xs font-bold text-on-surface leading-relaxed">{level.prizes}</p>
                          </div>
                        )}

                        {!level.prizes && hasIndividualPrizes && (
                          <div className="space-y-1 lg:space-y-1.5">
                            <div className="flex items-center gap-1.5 lg:gap-2 text-[11px] lg:text-xs font-black text-secondary">
                              <Trophy size={11} className="lg:w-3.5 lg:h-3.5" />
                              <span>الجوائز</span>
                            </div>
                            {individualPrizes.map((prize, pi) => {
                              if (!prize) return null;
                              return (
                                <div key={pi} className="flex items-center gap-2.5 bg-surface-container-low rounded-lg lg:rounded-xl px-3 lg:px-4 py-2 lg:py-2.5">
                                  <span className={`w-5 lg:w-6 h-5 lg:h-6 rounded-full flex items-center justify-center text-[9px] lg:text-[10px] font-black text-white shrink-0 ${pi === 0 ? 'bg-[#D4AF37]' : pi === 1 ? 'bg-[#A0A0A0]' : 'bg-[#CD7F32]'}`}>
                                    {pi + 1}
                                  </span>
                                  <span className="text-[11px] lg:text-xs font-bold text-on-surface">{prize}</span>
                                </div>
                              );
                            })}
                          </div>
                        )}

                        {level.notes && (
                          <div className="mt-auto bg-primary/[0.04] border border-primary/[0.08] rounded-lg lg:rounded-xl px-3 lg:px-4 py-2.5 lg:py-3">
                            <div className="flex items-center gap-1.5 mb-1">
                              <span className="w-1 h-1 rounded-full bg-primary/40" />
                              <span className="text-[10px] lg:text-[11px] font-black text-primary">ملاحظات</span>
                            </div>
                            <p className="text-[11px] lg:text-xs font-bold text-on-surface-variant leading-relaxed">
                              {level.notes}
                            </p>
                          </div>
                        )}
                      </div>
                    </motion.div>
                  );
                })}
              </div>
            )}
          </div>
        </section>
      </div>

      <Footer />
    </div>
  );
}
