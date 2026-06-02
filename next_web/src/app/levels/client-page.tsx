'use client';

import React, { useState, useCallback } from 'react';
import { Trophy, BookOpen, ChevronDown, RefreshCw } from 'lucide-react';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import { motion } from 'framer-motion';
import { getSupabase } from '@/lib/supabase';
import { LevelCardSkeleton } from '@/components/SkeletonLoader';
import type { CompetitionLevel } from '@/lib/database.types';

interface Props {
  initialLevels: CompetitionLevel[] | null;
  initialError: string | null;
}

export default function LevelsClient({ initialLevels, initialError }: Props) {
  const [levels, setLevels] = useState<CompetitionLevel[]>(initialLevels ?? []);
  const [loading, setLoading] = useState(!initialLevels && !initialError);
  const [error, setError] = useState<string | null>(initialError);

  const formatAge = (l: CompetitionLevel) => {
    const op = (l as any).age_op || (l as any).birth_year_op;
    if (op === 'gt') return `السن > ${l.min_age}`;
    if (op === 'gte') return `السن ≥ ${l.min_age}`;
    if (op === 'lt') return `السن < ${l.max_age}`;
    if (op === 'lte') return `السن ≤ ${l.max_age}`;
    if (op === 'range') return `من ${l.min_age} إلى ${l.max_age} سنة`;
    if (l.min_age && l.max_age) return `فوق ${l.min_age} - ${l.max_age} فأقل`;
    if (l.min_age) return `فوق ${l.min_age} عام`;
    if (l.max_age) return `${l.max_age} فأقل`;
    return 'جميع الأعمار';
  };

  const fetchLevels = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: supabaseError } = await supabase
        .from('competition_levels')
        .select('*')
        .eq('is_active', true)
        .order('level_code');

      if (supabaseError) throw supabaseError;
      if (data) setLevels(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'فشل في تحميل المستويات');
    } finally {
      setLoading(false);
    }
  }, []);

  return (
    <div className="min-h-screen bg-surface flex flex-col font-cairo overflow-x-hidden" dir="rtl">
      <Header />

      <div className="flex-1">
        <section className="relative min-h-[50vh] md:min-h-[55vh] flex items-center overflow-hidden bg-primary" style={{ clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 30px), 0 100%)' }}>
          <div className="absolute inset-0 islamic-pattern z-0 opacity-[0.5]" />
          <motion.div
            initial={{ opacity: 0, scale: 1.05 }}
            animate={{ opacity: 0.55, scale: 1 }}
            transition={{ duration: 2, ease: 'easeOut' }}
            className="absolute inset-0 z-[1]">
            <div className="absolute inset-0 bg-cover bg-center" style={{ backgroundImage: "url('/background.png')", backgroundPosition: 'center 40%' }} />
            <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-transparent to-primary/60" />
          </motion.div>
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 1.5, ease: 'easeOut' }}
            className="absolute -top-32 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-secondary-fixed/8 rounded-full blur-[120px] pointer-events-none z-[2]" />
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 1.5, ease: 'easeOut', delay: 0.2 }}
            className="absolute -bottom-48 -right-48 w-[600px] h-[600px] bg-secondary-fixed/6 rounded-full blur-[150px] pointer-events-none z-[2]" />
          <div className="absolute inset-0 bg-gradient-to-b from-primary/0 via-primary/15 via-50% to-primary/85 to-95% z-[3]" />
          <div className="max-w-7xl mx-auto px-6 relative z-10 text-center w-full py-20">
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
              className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-primary text-white font-black text-xs mb-5 shadow-md shadow-primary/20">
              <span className="w-1.5 h-1.5 rounded-full bg-primary-fixed animate-pulse" />
              فروع المسابقة
            </motion.div>
            <motion.h1 initial={{ opacity: 0, y: 20, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 0.8, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
              className="text-[32px] sm:text-[44px] md:text-[56px] font-black text-white leading-[1.2] mb-3"
              style={{ fontFamily: "'Noto Serif', serif", textShadow: '0 0 60px rgba(255,224,136,0.3), 0 0 20px rgba(255,224,136,0.2), 0 4px 12px rgba(0,0,0,0.6)' }}>
              المستويات وشروطها
            </motion.h1>
            <div className="flex items-center justify-center gap-2 mt-3 mb-6">
              <span className="w-8 h-0.5 rounded-full bg-secondary-fixed/30" />
              <span className="w-2 h-2 rounded-full bg-secondary-fixed/60" />
              <span className="w-8 h-0.5 rounded-full bg-secondary-fixed/30" />
            </div>
            <motion.p initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.5 }}
              className="text-white text-sm sm:text-base max-w-xl mx-auto leading-relaxed font-semibold"
              style={{ textShadow: '0 2px 8px rgba(0,0,0,0.5)' }}>
              تعرف على فروع المسابقة، الشروط العمرية، والجوائز المخصصة لكل مستوى
            </motion.p>
          </div>
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 1.5, duration: 0.5 }}
            className="absolute bottom-6 left-1/2 -translate-x-1/2 animate-bounce z-10">
            <ChevronDown className="text-secondary-fixed text-3xl" />
          </motion.div>
        </section>

        <section className="relative py-16 bg-gradient-to-b from-surface via-surface to-surface-container-low overflow-hidden">
          <div className="max-w-7xl mx-auto px-6 relative z-10">
            {loading ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 md:gap-6">
                {[...Array(6)].map((_, i) => <LevelCardSkeleton key={i} />)}
              </div>
            ) : error ? (
              <div className="text-center py-16 bg-surface-container-low rounded-2xl border border-outline-variant/10">
                <BookOpen size={32} className="mx-auto text-red-300 mb-3" />
                <p className="text-on-surface-variant font-bold text-sm mb-2">فشل في تحميل المستويات</p>
                <p className="text-xs text-on-surface-variant/60 mb-4">{error}</p>
                <button onClick={fetchLevels}
                  className="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-white rounded-xl font-bold text-sm hover:bg-primary/90 transition-colors">
                  <RefreshCw className="w-4 h-4" />إعادة المحاولة
                </button>
              </div>
            ) : levels.length === 0 ? (
              <div className="text-center py-16 bg-surface-container-low rounded-2xl border border-outline-variant/10">
                <BookOpen size={32} className="mx-auto text-on-surface-variant/30 mb-3" />
                <p className="text-on-surface-variant font-bold text-sm">لا تتوفر مستويات نشطة حالياً</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 md:gap-6">
                {levels.map((level, i) => {
                  const individualPrizes = [level.first_prize, level.second_prize, level.third_prize];
                  const hasIndividualPrizes = individualPrizes.some(Boolean);
                  const codeNum = String(level.level_code).replace(/\D/g, '');
                  return (
                    <motion.div key={level.id ?? i}
                      initial={{ opacity: 0, y: 20 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true, margin: '-50px' }}
                      transition={{ duration: 0.3, delay: Math.min(i * 0.04, 0.3), ease: [0.16, 1, 0.3, 1] }}
                      whileHover={{ y: -4 }}
                      className="bg-white rounded-xl shadow-md hover:shadow-lg transition-all duration-300 flex flex-col overflow-hidden border border-outline-variant/10">
                      <div className="bg-primary px-4 py-3 flex items-center gap-2.5 relative overflow-hidden">
                        <div className="absolute inset-0 islamic-pattern opacity-10" />
                        <span className="w-9 h-9 rounded-xl bg-gradient-to-br from-secondary-fixed to-[#fed65b] text-on-secondary-fixed flex items-center justify-center font-black text-sm shrink-0 shadow-sm">
                          {codeNum || level.level_code}
                        </span>
                        <div className="flex-1 min-w-0 flex items-baseline gap-2">
                          <h3 className="text-white font-black text-sm leading-tight">{level.title}</h3>
                        </div>
                        {(level.min_age || level.max_age) && (
                          <span className="text-[10px] font-black text-secondary-fixed bg-white/10 px-2 py-0.5 rounded-lg shrink-0">
                            {formatAge(level)}
                          </span>
                        )}
                      </div>
                      <div className="p-4 flex-1 flex flex-col gap-3 relative">
                        <div className="absolute inset-0 islamic-pattern opacity-[0.08] pointer-events-none" />
                        <p className="text-sm font-bold text-primary leading-relaxed relative z-[1]">{level.content}</p>
                        {level.prizes && (
                          <div className="bg-gradient-to-br from-secondary-fixed/[0.12] to-transparent rounded-xl p-3.5 border border-secondary-fixed/20 relative z-[1]">
                            <div className="flex items-center gap-1.5 text-xs font-black text-secondary mb-1">
                              <Trophy size={13} /><span>الجوائز</span>
                            </div>
                            <p className="text-xs font-bold text-on-surface leading-relaxed">{level.prizes}</p>
                          </div>
                        )}
                        {!level.prizes && hasIndividualPrizes && (
                          <div className="space-y-1.5">
                            <div className="flex items-center gap-1.5 text-xs font-black text-secondary">
                              <Trophy size={13} /><span>الجوائز</span>
                            </div>
                            {individualPrizes.map((prize, pi) => {
                              if (!prize) return null;
                              return (
                                <div key={pi} className="flex items-center gap-2.5 bg-surface-container-low rounded-xl px-3.5 py-2.5">
                                  <span className={`w-6 h-6 rounded-full flex items-center justify-center text-[9px] font-black text-white shrink-0 shadow-sm ${pi === 0 ? 'bg-gradient-to-br from-[#D4AF37] to-[#B8942E]' : pi === 1 ? 'bg-gradient-to-br from-[#A0A0A0] to-[#808080]' : 'bg-gradient-to-br from-[#CD7F32] to-[#B06A28]'}`}>
                                    {pi + 1}
                                  </span>
                                  <span className="text-xs font-bold text-on-surface">{prize}</span>
                                </div>
                              );
                            })}
                          </div>
                        )}
                        {level.notes && (
                          <div className="mt-auto bg-primary/[0.04] border border-primary/[0.08] rounded-xl px-3.5 py-2.5">
                            <div className="flex items-center gap-1.5 mb-1">
                              <span className="w-1 h-1 rounded-full bg-primary/40" />
                              <span className="text-[10px] font-black text-primary">ملاحظات</span>
                            </div>
                            <p className="text-xs font-bold text-on-surface-variant leading-relaxed">{level.notes}</p>
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
