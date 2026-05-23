'use client';

import React, { useState, useRef, useEffect } from 'react';
import { CreditCard, Search, Award, Info, User, Layers, Printer, Download, BookOpen, Star, Hash, ArrowRightLeft } from 'lucide-react';
import Image from 'next/image';
import toast from 'react-hot-toast';

interface StudentData {
  id: number;
  name: string;
  gender: 'M' | 'F' | string;
  level: string;
  level_content: string;
  student_code: string;
  profile_image_url: string | null;
  score: number | null;
  rewaya_score: number | null;
  selected_rewaya: string | null;
  tajweed_score: number | null;
  voice_score: number | null;
  meaning_score: number | null;
}

interface LevelData {
  content: string;
  total_points: number;
  has_rewaya: boolean;
  rewaya_max_score: number;
  has_tajweed: boolean;
  tajweed_max_score: number;
  has_voice: boolean;
  voice_max_score: number;
  has_meaning: boolean;
  meaning_max_score: boolean;
}

export default function ResultInquiry() {
  const [nationalId, setNationalId] = useState('');
  const [isOpen, setIsOpen] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(false);
  const [checkingStatus, setCheckingStatus] = useState(true);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const [student, setStudent] = useState<StudentData | null>(null);
  const [level, setLevel] = useState<LevelData | null>(null);

  const certificateRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);
  const [certificateHeight, setCertificateHeight] = useState(0);
  const [isDownloading, setIsDownloading] = useState(false);

  // Check if result query is open on mount
  useEffect(() => {
    const checkStatus = async () => {
      try {
        const res = await fetch('/api/result');
        const data = await res.json();
        if (res.ok) {
          setIsOpen(data.is_result_query_open);
        } else {
          setIsOpen(false);
        }
      } catch (err) {
        console.error('Error checking status:', err);
        setIsOpen(false);
      } finally {
        setCheckingStatus(false);
      }
    };
    checkStatus();
  }, []);

  const handleInquiry = async (e: React.FormEvent) => {
    e.preventDefault();
    if (nationalId.length !== 14) {
      setError('الرقم القومي يجب أن يتكون من 14 رقماً');
      return;
    }

    setError('');
    setLoading(true);
    setSearched(true);
    setStudent(null);
    setLevel(null);

    try {
      const response = await fetch('/api/result', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ nationalId }),
      });

      const resData = await response.json();

      if (!response.ok) {
        setError(resData.error || 'حدث خطأ أثناء الاستعلام');
        return;
      }

      setStudent(resData.student);
      setLevel(resData.level);
    } catch (err) {
      console.error('Fetch error:', err);
      setError('فشل الاتصال بالخادم. يرجى المحاولة مرة أخرى.');
    } finally {
      setLoading(false);
    }
  };

  const handleNewSearch = () => {
    setStudent(null);
    setLevel(null);
    setSearched(false);
    setError('');
    setNationalId('');
  };

  // Calculate scores
  const getScoreDetails = () => {
    if (!student || !level) return { totalScore: 0, maxScore: 100, percentage: 0, grade: '' };

    let maxScore = level.total_points ?? 100;
    let totalScore = student.score ?? 0;

    if (level.has_rewaya) {
      maxScore += level.rewaya_max_score ?? 100;
      totalScore += student.rewaya_score ?? 0;
    }
    if (level.has_tajweed) {
      maxScore += level.tajweed_max_score ?? 100;
      totalScore += student.tajweed_score ?? 0;
    }
    if (level.has_voice) {
      maxScore += level.voice_max_score ?? 100;
      totalScore += student.voice_score ?? 0;
    }
    if (level.has_meaning) {
      // @ts-ignore
      maxScore += level.meaning_max_score ?? 100;
      totalScore += student.meaning_score ?? 0;
    }

    const percentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0;

    let grade = 'لم يجتز';
    if (percentage >= 95) grade = 'ممتاز مع مرتبة الشرف';
    else if (percentage >= 90) grade = 'ممتاز';
    else if (percentage >= 80) grade = 'جيد جداً';
    else if (percentage >= 70) grade = 'جيد';
    else if (percentage >= 50) grade = 'مقبول';

    return { totalScore, maxScore, percentage, grade };
  };

  const downloadAsImage = async () => {
    if (!student) return;
    setIsDownloading(true);
    const toastId = toast.loading('جاري تجهيز وثيقة النتيجة وتحميلها كصورة...');
    try {
      const html2canvas = (await import('html2canvas-pro')).default;
      const el = document.getElementById('result-ticket');
      if (!el) return;
      
      const canvas = await html2canvas(el, {
        scale: 2,
        useCORS: true,
        backgroundColor: '#ffffff',
        logging: false,
        windowWidth: 850,
        windowHeight: el.scrollHeight + 150,
        onclone: (clonedDoc) => {
          const clonedEl = clonedDoc.getElementById('result-ticket');
          if (clonedEl) {
            clonedEl.style.transform = 'none';
            clonedEl.style.transformOrigin = 'top center';
            clonedEl.style.width = '800px';
            clonedEl.style.height = 'auto';
            
            const clonedParent = clonedEl.parentElement;
            if (clonedParent) {
              clonedParent.style.height = 'auto';
              clonedParent.style.overflow = 'visible';
              clonedParent.style.transform = 'none';
            }
          }
        }
      });
      
      const dataUrl = canvas.toDataURL('image/png');
      const link = document.createElement('a');
      link.href = dataUrl;
      link.download = `نتيجة_المتسابق_${student.name.replace(/\s+/g, '_')}.png`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      toast.success('تم تحميل وثيقة النتيجة بنجاح!', { id: toastId });
    } catch (err) {
      console.error(err);
      toast.error('فشل تحميل الصورة، يرجى المحاولة مرة أخرى.', { id: toastId });
    } finally {
      setIsDownloading(false);
    }
  };

  useEffect(() => {
    if (!student) return;

    const handleResize = () => {
      const width = window.innerWidth;
      const targetWidth = 800;
      const padding = 32; 
      if (width < targetWidth + padding) {
        setScale((width - padding) / targetWidth);
      } else {
        setScale(1);
      }
    };

    handleResize();
    window.addEventListener('resize', handleResize);

    const resizeObserver = new ResizeObserver(() => {
      if (certificateRef.current) {
        setCertificateHeight(certificateRef.current.scrollHeight);
      }
    });

    if (certificateRef.current) {
      resizeObserver.observe(certificateRef.current);
    }

    return () => {
      window.removeEventListener('resize', handleResize);
      resizeObserver.disconnect();
    };
  }, [student]);

  if (checkingStatus) {
    return (
      <div className="flex flex-col items-center justify-center py-16 animate-fade-in">
        <div className="w-10 h-10 border-4 border-[var(--border)] border-t-[var(--primary)] rounded-full animate-spin mb-4"></div>
        <p className="text-slate-500 text-sm font-semibold">جاري التحقق من حالة إعلان النتائج...</p>
      </div>
    );
  }
  if (isOpen === false) {
    return (
      <div className="bg-[var(--bg-section)] border border-[var(--border)] rounded-3xl p-8 sm:p-10 text-center animate-fade-in max-w-md mx-auto">
        <div className="w-16 h-16 bg-white border border-[var(--border)] text-[var(--text-primary)] rounded-full flex items-center justify-center mx-auto mb-4 shadow-sm">
          <Award size={32} />
        </div>
        <h2 className="text-2xl font-black text-[var(--text-primary)] mb-3">قريباً جداً</h2>
        <p className="text-[var(--text-secondary)] text-sm font-semibold leading-relaxed">
          سيتم إتاحة الاستعلام عن النتيجة النهائية بالتفصيل لجميع الفئات والمستويات فور الانتهاء من رصد وتدقيق الدرجات واعتمادها بشكل رسمي من لجنة التحكيم والمشرف العام. نسأل الله التوفيق لجميع المتسابقين.
        </p>
      </div>
    );
  }

  const { totalScore, maxScore, percentage, grade } = getScoreDetails();

  const getGradeBadgeStyles = (gradeStr: string) => {
    switch (gradeStr) {
      case 'ممتاز مع مرتبة الشرف':
        return { color: 'var(--text-primary)', bg: 'var(--bg-section)', border: 'var(--border)', label: 'امتياز مع مرتبة الشرف' };
      case 'ممتاز':
        return { color: 'var(--text-primary)', bg: 'var(--bg-section)', border: 'var(--border)', label: 'امتياز' };
      case 'جيد جداً':
        return { color: 'var(--text-primary)', bg: 'var(--bg-section)', border: 'var(--border)', label: 'جيد جداً' };
      case 'جيد':
        return { color: '#475569', bg: 'var(--bg-section)', border: 'var(--border)', label: 'جيد' };
      case 'مقبول':
        return { color: '#475569', bg: 'var(--bg-section)', border: 'var(--border)', label: 'مقبول' };
      default:
        return { color: '#991b1b', bg: '#fee2e2', border: '#fecaca', label: 'لم يجتز' };
    }
  };

  const badge = getGradeBadgeStyles(grade);

  if (student && level) {
    return (
      <div className="w-full mx-auto animate-fade-in" dir="rtl" style={{ fontFamily: 'Cairo, sans-serif' }}>
        <style dangerouslySetInnerHTML={{ __html: `
          @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700;950&display=swap');
          @media print {
            @page { margin: 0; }
            .print-no-scale {
              transform: none !important;
              width: 100% !important;
              height: auto !important;
            }
            body * {
              visibility: hidden;
            }
            #result-ticket-container, #result-ticket-container * {
              visibility: visible;
            }
            #result-ticket-container {
              position: absolute;
              left: 0;
              top: 0;
              width: 100%;
            }
          }
        ` }} />

        {/* ── ACTIONS BAR ── */}
        <div className="w-full max-w-[800px] mx-auto mb-6 p-2.5 bg-white border border-[var(--border)] rounded-2xl flex flex-col sm:flex-row items-center justify-between gap-3 shadow-sm print:hidden">
          <button 
            onClick={handleNewSearch} 
            className="flex items-center gap-1.5 text-slate-700 hover:text-slate-900 font-bold text-xs sm:text-sm transition-all py-2 px-3 hover:bg-slate-50 rounded-xl active:scale-95"
          >
            <Search size={16} className="text-slate-400" />
            <span>استعلام جديد</span>
          </button>
          
          <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
            <button 
              onClick={downloadAsImage} 
              disabled={isDownloading}
              className="flex-1 sm:flex-initial flex items-center justify-center gap-1.5 bg-[var(--primary)] hover:bg-[var(--primary-hover)] disabled:bg-slate-400 text-white font-bold text-xs sm:text-sm py-2.5 px-4 rounded-xl shadow-sm hover:shadow active:scale-95 transition-all cursor-pointer whitespace-nowrap"
            >
              <Download size={15} className={isDownloading ? 'animate-spin' : ''} />
              <span>{isDownloading ? 'جاري التحميل...' : 'حفظ كصورة'}</span>
            </button>

            <button 
              onClick={() => window.print()} 
              className="flex-1 sm:flex-initial flex items-center justify-center gap-1.5 bg-[var(--bg-section)] hover:bg-[var(--bg-section)] text-[var(--text-primary)] border border-[var(--border)] font-bold text-xs sm:text-sm py-2.5 px-4 rounded-xl shadow-sm hover:shadow active:scale-95 transition-all cursor-pointer whitespace-nowrap"
            >
              <Printer size={15} />
              <span>طباعة الاستمارة</span>
            </button>
          </div>
        </div>

        {/* ── CERTIFICATE CONTAINER ── */}
        <div 
          id="result-ticket-container"
          className="w-full flex justify-center overflow-hidden print:block print:w-full print:h-auto print:overflow-visible mb-8 print:mb-0" 
          style={{ height: scale < 1 ? `${(certificateHeight + 16) * scale}px` : 'auto' }}
        >
          <div 
            id="result-ticket" 
            className="print-no-scale bg-white border border-[var(--border)] shadow-md rounded-3xl print:border-none print:rounded-none print:shadow-none flex-shrink-0" 
            style={{ 
              transform: scale < 1 ? `scale(${scale})` : 'none', 
              transformOrigin: 'top center',
              width: '800px',
              fontFamily: '"Cairo", sans-serif', 
              direction: 'rtl' 
            }}
          >
            <div ref={certificateRef} style={{ padding: '36pt 24pt 36pt 24pt', position: 'relative' }}>
              {/* Background watermark lines */}
              <div style={{ position: 'absolute', top: '10pt', left: '10pt', right: '10pt', bottom: '10pt', border: '1.5pt solid var(--border)', borderRadius: '18pt', opacity: 0.15, pointerEvents: 'none' }} />
              <div style={{ position: 'absolute', top: '14pt', left: '14pt', right: '14pt', bottom: '14pt', border: '0.75pt dashed var(--border)', borderRadius: '15pt', opacity: 0.2, pointerEvents: 'none' }} />

              {/* ── HEADER ───── */}
              <div style={{ paddingBottom: '14pt', borderBottom: '2.5pt solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'relative', zIndex: 1 }}>
                <div style={{ display: 'flex', flexDirection: 'column', flex: 1, paddingLeft: '16pt' }}>
                  <h1 style={{ color: 'var(--text-primary)', fontSize: '20pt', fontWeight: 900, margin: 0, lineHeight: 1.2, fontFamily: '"Cairo", sans-serif' }}>مسابقة أهل القرآن الكبرى</h1>
                  <p style={{ color: 'var(--beige-dark)', fontSize: '13pt', fontWeight: 700, margin: '4pt 0 0 0', lineHeight: 1, fontFamily: '"Cairo", sans-serif' }}>وثيقة بيان الدرجات والنتيجة التفصيلية</p>
                </div>
                <div style={{ width: '65pt', height: '65pt', borderRadius: '50%', overflow: 'hidden', flexShrink: 0, border: '2pt solid var(--border)', padding: '1pt', backgroundColor: 'white' }}>
                  <img src="/logo_musapaka.jpeg" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                </div>
              </div>

              {/* ───── BODY ───── */}
              <div style={{ paddingTop: '20pt', position: 'relative', zIndex: 1 }}>

                {/* ── PERSONAL INFO CARD ── */}
                <div style={{ border: '1px solid var(--border)', borderRadius: '12pt', padding: '14pt 16pt', backgroundColor: 'var(--bg-section)', display: 'flex', justifyItems: 'center', justifyContent: 'space-between', alignItems: 'center', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8pt' }}>
                    <FlutterIconRow label="اسم المتسابق" value={student.name} icon={<User size="12pt" color="white" />} />
                    <FlutterIconRow label="كود المتسابق" value={student.student_code} icon={<Hash size="12pt" color="white" />} valueColor="var(--text-primary)" />
                    <FlutterIconRow label="المستوى" value={student.level} icon={<Layers size="12pt" color="white" />} />
                    <FlutterIconRow label="المحتوى" value={student.level_content} icon={<BookOpen size="12pt" color="white" />} />
                  </div>

                  <div style={{ width: '90pt', minWidth: '90pt', marginRight: '20pt', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <div style={{ width: '90pt', height: '90pt', borderRadius: '50%', border: '2.5pt solid var(--primary)', overflow: 'hidden', backgroundColor: '#f8fafc', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)' }}>
                      {student.profile_image_url ? (
                        <img src={student.profile_image_url} alt="Profile" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      ) : (
                        <User size="45pt" color="#94a3b8" />
                      )}
                    </div>
                  </div>
                </div>

                <div style={{ height: '20pt' }} />

                {/* ── DETAILED SCORE BREAKDOWN ── */}
                <h3 style={{ fontSize: '13pt', fontWeight: 800, color: 'var(--text-primary)', marginBottom: '8pt', fontFamily: '"Cairo", sans-serif', paddingRight: '4pt' }}>تفاصيل نتائج فروع التقييم:</h3>
                
                <div style={{ overflow: 'hidden', border: '1px solid var(--border)', borderRadius: '12pt', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'right', fontSize: '11pt', fontFamily: '"Cairo", sans-serif' }}>
                    <thead>
                      <tr style={{ backgroundColor: 'var(--primary)', color: 'white', fontWeight: 900 }}>
                        <th style={{ padding: '10pt 12pt' }}>الفرع الاختباري</th>
                        <th style={{ padding: '10pt 12pt', textAlign: 'center' }}>الدرجة المستحقة</th>
                        <th style={{ padding: '10pt 12pt', textAlign: 'center' }}>الدرجة العظمى</th>
                        <th style={{ padding: '10pt 12pt', textAlign: 'center' }}>النسبة</th>
                      </tr>
                    </thead>
                    <tbody>
                      {/* 1. Base Score */}
                      <tr style={{ borderBottom: '1pt solid #f1f5f9' }}>
                        <td style={{ padding: '10pt 12pt', fontWeight: 700, color: '#334155' }}>حفظ ومراجعة القرآن الكريم</td>
                        <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 750, color: 'var(--text-primary)' }}>{student.score ?? 0}</td>
                        <td style={{ padding: '10pt 12pt', textAlign: 'center', color: '#64748b' }}>{level.total_points}</td>
                        <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 700, color: 'var(--text-primary)' }}>
                          {(((student.score ?? 0) / (level.total_points > 0 ? level.total_points : 1)) * 100).toFixed(1)}%
                        </td>
                      </tr>

                      {/* 2. Rewaya Score */}
                      {level.has_rewaya && (
                        <tr style={{ borderBottom: '1pt solid #f1f5f9', backgroundColor: 'var(--bg-section)' }}>
                          <td style={{ padding: '10pt 12pt', fontWeight: 700, color: '#334155' }}>
                            الرواية المقروء بها <span style={{ color: 'var(--beige-dark)', fontSize: '9pt' }}>({student.selected_rewaya || 'رواية افتراضية'})</span>
                          </td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 750, color: 'var(--text-primary)' }}>{student.rewaya_score ?? 0}</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', color: '#64748b' }}>{level.rewaya_max_score}</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 700, color: 'var(--text-primary)' }}>
                            {(((student.rewaya_score ?? 0) / (level.rewaya_max_score > 0 ? level.rewaya_max_score : 1)) * 100).toFixed(1)}%
                          </td>
                        </tr>
                      )}

                      {/* 3. Tajweed Score */}
                      {level.has_tajweed && (
                        <tr style={{ borderBottom: '1pt solid #f1f5f9' }}>
                          <td style={{ padding: '10pt 12pt', fontWeight: 700, color: '#334155' }}>أحكام التجويد ومخارج الحروف</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 750, color: 'var(--text-primary)' }}>{student.tajweed_score ?? 0}</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', color: '#64748b' }}>{level.tajweed_max_score}</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 700, color: 'var(--text-primary)' }}>
                            {(((student.tajweed_score ?? 0) / (level.tajweed_max_score > 0 ? level.tajweed_max_score : 1)) * 100).toFixed(1)}%
                          </td>
                        </tr>
                      )}

                      {/* 4. Voice Score */}
                      {level.has_voice && (
                        <tr style={{ borderBottom: '1pt solid #f1f5f9', backgroundColor: 'var(--bg-section)' }}>
                          <td style={{ padding: '10pt 12pt', fontWeight: 700, color: '#334155' }}>جمال وحسن الصوت والأداء</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 750, color: 'var(--text-primary)' }}>{student.voice_score ?? 0}</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', color: '#64748b' }}>{level.voice_max_score}</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 700, color: 'var(--text-primary)' }}>
                            {(((student.voice_score ?? 0) / (level.voice_max_score > 0 ? level.voice_max_score : 1)) * 100).toFixed(1)}%
                          </td>
                        </tr>
                      )}

                      {/* 5. Meaning Score */}
                      {/* @ts-ignore */}
                      {level.has_meaning && (
                        <tr style={{ borderBottom: '1pt solid #f1f5f9' }}>
                          <td style={{ padding: '10pt 12pt', fontWeight: 700, color: '#334155' }}>تفسير ومعاني الكلمات القرآنية</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 750, color: 'var(--text-primary)' }}>{student.meaning_score ?? 0}</td>
                          {/* @ts-ignore */}
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', color: '#64748b' }}>{level.meaning_max_score}</td>
                          <td style={{ padding: '10pt 12pt', textAlign: 'center', fontWeight: 700, color: 'var(--text-primary)' }}>
                            {/* @ts-ignore */}
                            {(((student.meaning_score ?? 0) / (level.meaning_max_score > 0 ? level.meaning_max_score : 1)) * 100).toFixed(1)}%
                          </td>
                        </tr>
                      )}

                      {/* Total Highlights Row */}
                      <tr style={{ backgroundColor: 'var(--bg-section)', borderTop: '2px solid var(--primary)', fontSize: '12pt', fontWeight: 800 }}>
                        <td style={{ padding: '12pt 12pt', color: 'var(--text-primary)' }}>المجموع الكلي النهائي</td>
                        <td style={{ padding: '12pt 12pt', textAlign: 'center', color: 'var(--text-primary)', fontSize: '13pt' }}>{totalScore}</td>
                        <td style={{ padding: '12pt 12pt', textAlign: 'center', color: 'var(--text-primary)' }}>{maxScore}</td>
                        <td style={{ padding: '12pt 12pt', textAlign: 'center', color: 'var(--text-primary)', fontSize: '14pt', fontWeight: 950 }}>
                          {percentage.toFixed(1)}%
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <div style={{ height: '24pt' }} />

                {/* ── OVERALL GRADE & NOTE ── */}
                <div style={{ position: 'relative' }}>
                  <div style={{ border: '1px solid var(--border)', borderRadius: '12pt', padding: '22pt 16pt 16pt 16pt', backgroundColor: 'var(--bg-section)', textAlign: 'center' }}>
                    <p style={{ fontSize: '13pt', fontWeight: 700, color: 'var(--text-primary)', lineHeight: 1.6, fontFamily: '"Cairo", sans-serif', margin: 0 }}>
                      {percentage >= 50 ? (
                        <>
                          تهانينا القلبية! لقد اجتزت اختبارات المسابقة بنجاح وتفوق وحصلت على تقدير <span style={{ color: badge.color, fontWeight: 900 }}>({badge.label})</span> بنسبة <span style={{ color: 'var(--text-primary)', fontWeight: 900 }}>{percentage.toFixed(1)}%</span>. سائلين المولى عز وجل أن يجعلك من حفظة كتابه والعاملين به.
                        </>
                      ) : (
                        <>
                          نسأل الله لك التوفيق والسداد. لقد حصلت على نسبة <span style={{ color: '#991b1b', fontWeight: 900 }}>{percentage.toFixed(1)}%</span> بتقدير <span style={{ color: '#991b1b', fontWeight: 900 }}>({badge.label})</span>. شدّ حيلك وندعو الله أن يوفقك لاجتيازها بامتياز وتفوق في الفترات القادمة.
                        </>
                      )}
                    </p>
                  </div>
                  {/* Badge Overlay */}
                  <div style={{ 
                    position: 'absolute', 
                    top: 0, 
                    left: '50%', 
                    transform: 'translate(-50%, -50%)', 
                    backgroundColor: badge.bg, 
                    padding: '5pt 16pt', 
                    borderRadius: '16pt', 
                    border: `1.5pt solid ${badge.border}`, 
                    display: 'flex', 
                    alignItems: 'center',
                    boxShadow: '0 2px 4px rgba(0,0,0,0.03)'
                  }}>
                    <div style={{ padding: '3pt', backgroundColor: badge.color, borderRadius: '4pt', display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 0 }}>
                      <Award size="10pt" color="white" />
                    </div>
                    <span style={{ marginRight: '6pt' }} />
                    <span style={{ fontSize: '12pt', fontWeight: 950, color: badge.color, fontFamily: "'Cairo', sans-serif" }}>
                      التقدير العام: {badge.label}
                    </span>
                  </div>
                </div>

                <div style={{ height: '32pt' }} />

                {/* ── SUPERVISOR ── */}
                <div style={{ textAlign: 'center' }}>
                  <p style={{ color: 'var(--beige-dark)', fontSize: '11pt', fontWeight: 900, margin: 0, fontFamily: "'Cairo', sans-serif" }}>المشرف العام علي المسابقة</p>
                  <p style={{ color: 'var(--text-primary)', fontSize: '16pt', fontWeight: 900, margin: '3pt 0 0 0', fontFamily: "'Cairo', sans-serif" }}>أ/ مصطفى عبدالرحمن محمد سالم</p>
                  <p style={{ color: '#64748b', fontSize: '10.5pt', fontWeight: 600, margin: '6pt 0 0 0', fontFamily: "'Cairo', sans-serif" }}>مقر اللجنة: مركز فاقوس - قرية الديدمون - شارع الشيخ - منزل المشرف العام</p>
                </div>

                <div style={{ height: '24pt' }} />

                {/* ── FOOTER SIGN ── */}
                <div style={{ padding: '8pt 16pt', border: '1px solid var(--border)', borderRadius: '10pt', backgroundColor: 'var(--bg-section)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8pt' }}>
                  <Info size="14pt" color="var(--text-primary)" />
                  <span style={{ fontSize: '10pt', fontWeight: 700, color: 'var(--text-primary)', fontFamily: '"Cairo", sans-serif' }}>
                    هذه الوثيقة رسمية ومعتمدة من إدارة المسابقة لتوضيح تفاصيل التقييم.
                  </span>
                </div>

              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full animate-fade-in">
      <div className="text-center mb-8">
        <div className="inline-flex items-center justify-center w-12 h-12 bg-[var(--bg-section)] text-[var(--text-primary)] rounded-2xl mb-4 border border-[var(--border)] shadow-sm">
          <Award size={24} />
        </div>
        <h2 className="text-xl font-black text-[var(--text-primary)] mb-2">استعلام النتيجة وبيان الدرجات التفصيلي</h2>
        <p className="text-slate-500 text-xs sm:text-sm font-semibold max-w-sm mx-auto leading-relaxed">
          أدخل الرقم القومي للمتسابق لمعرفة الدرجات التفصيلية والتقدير النهائي وحفظ شهادة النتيجة.
        </p>
      </div>

      <form onSubmit={handleInquiry} className="space-y-5 max-w-md mx-auto">
        <div className="space-y-1.5 relative">
          <label className="block text-sm font-bold text-[var(--text-primary)]">الرقم القومي للمتسابق <span className="text-red-500">*</span></label>
          <div className="relative group">
            <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-[var(--primary)] transition-colors">
              <CreditCard size={17} />
            </span>
            <input
              type="number"
              value={nationalId}
              onChange={e => { setNationalId(e.target.value); setError(''); setSearched(false); }}
              placeholder="أدخل الـ 14 رقماً للمتسابق"
              className={`w-full bg-[var(--bg-section)] border ${searched && nationalId.length !== 14 ? 'border-red-300 focus:border-red-500 focus:ring-red-200' : 'border-[var(--border)] focus:border-[var(--primary)] focus:ring-[var(--primary-glow)]'} rounded-xl px-10 py-3.5 text-sm font-semibold outline-none transition-all focus:bg-white focus:ring-4 text-[var(--text-primary)]`}
              required
            />
          </div>
          {searched && nationalId.length !== 14 && <p className="text-red-500 text-xs font-bold mt-1">الرقم القومي يجب أن يتكون من 14 رقماً</p>}
        </div>

        {error && <p className="text-red-500 text-xs font-bold text-center mt-2">{error}</p>}

        <button
          type="submit"
          disabled={loading || nationalId.length !== 14}
          className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-bold bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed mt-2"
        >
          {loading ? (
            <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <>
              <span>استعلام عن النتيجة</span>
              <Award size={16} />
            </>
          )}
        </button>
      </form>
    </div>
  );
}

function FlutterIconRow({ label, value, icon, valueColor = 'var(--text-primary)' }: { label: string; value: string; icon: React.ReactNode; valueColor?: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', fontFamily: '"Cairo", sans-serif' }}>
      <div style={{ padding: '5pt', backgroundColor: 'var(--primary)', borderRadius: '6pt', display: 'flex', alignItems: 'center', justifyItems: 'center', justifyContent: 'center', flexShrink: 0, lineHeight: 0 }}>
        {icon}
      </div>
      <span style={{ marginRight: '8pt', fontSize: '11.5pt', fontWeight: 500, color: '#475569', whiteSpace: 'nowrap', fontFamily: '"Cairo", sans-serif' }}>{label}</span>
      <span style={{ marginRight: '4pt', fontSize: '11.5pt', fontWeight: 500, color: '#475569', fontFamily: '"Cairo", sans-serif' }}>:</span>
      <span style={{ marginRight: '8pt', fontSize: '12pt', fontWeight: 750, color: valueColor, textAlign: 'right', flex: 1, fontFamily: '"Cairo", sans-serif' }}>{value}</span>
    </div>
  );
}
