'use client';

import React from 'react';
import Link from 'next/link';

function EnvelopeIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="4" width="20" height="16" rx="2" />
      <path d="M22 4L12 13L2 4" />
    </svg>
  );
}

function PhoneIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z" />
    </svg>
  );
}

export default function Footer() {
  return (
    <footer className="w-full bg-primary text-on-primary" dir="rtl">
      <div className="relative">
        <div className="absolute inset-0 islamic-pattern z-0 opacity-[0.04]" />
        <div className="relative z-10 max-w-7xl mx-auto px-6 py-14 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-10">
          {/* Brand */}
          <div className="lg:col-span-1">
            <div className="text-xl font-black text-secondary-fixed mb-4" style={{ fontFamily: "'Noto Serif', serif" }}>
              مسابقة أهل القرآن الكبرى
            </div>
            <p className="text-on-primary/40 text-sm leading-relaxed max-w-xs">
              منصة متكاملة لإدارة المسابقات القرآنية، من التسجيل حتى التكريم.
            </p>
          </div>

          {/* Links */}
          <div className="flex flex-col gap-3">
            <h5 className="text-white font-black text-sm mb-1">المنصة</h5>
            <Link href="/register" className="text-on-primary/50 text-sm font-bold hover:text-secondary-fixed transition-colors">التسجيل</Link>
            <Link href="/levels" className="text-on-primary/50 text-sm font-bold hover:text-secondary-fixed transition-colors">المستويات</Link>
            <Link href="/status" className="text-on-primary/50 text-sm font-bold hover:text-secondary-fixed transition-colors">الاستعلام</Link>
            <Link href="/status?tab=result" className="text-on-primary/50 text-sm font-bold hover:text-secondary-fixed transition-colors">النتائج</Link>
          </div>

          {/* Contact */}
          <div className="flex flex-col gap-3">
            <h5 className="text-white font-black text-sm mb-1">تواصل</h5>
            <div className="flex items-center gap-2.5 text-on-primary/50 text-sm font-bold">
              <EnvelopeIcon className="w-3.5 h-3.5 text-secondary-fixed shrink-0" />
              <span>contest@quran.sa</span>
            </div>
            <div className="flex items-start gap-2.5 text-on-primary/50 text-sm font-bold">
              <PhoneIcon className="w-3.5 h-3.5 text-secondary-fixed shrink-0 mt-0.5" />
              <div className="flex flex-col gap-1">
                <span className="text-[11px] text-on-primary/30 font-bold">للاستفسار:</span>
                <a href="tel:+201020804882" className="hover:text-secondary-fixed transition-colors" dir="ltr">01020804882</a>
                <a href="tel:+201008799886" className="hover:text-secondary-fixed transition-colors" dir="ltr">01008799886</a>
                <a href="tel:+201040546483" className="hover:text-secondary-fixed transition-colors" dir="ltr">01040546483</a>
              </div>
            </div>
          </div>

          {/* About */}
          <div className="flex flex-col gap-3">
            <h5 className="text-white font-black text-sm mb-1">عن المسابقة</h5>
            <p className="text-on-primary/40 text-sm leading-relaxed">
              مسابقة في حفظ وتلاوة القرآن الكريم، تستهدف جميع الفئات العمرية.
            </p>
          </div>
        </div>
      </div>

      <div className="border-t border-white/5">
        <div className="max-w-7xl mx-auto px-6 py-6 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-on-primary/25 text-xs">
            جميع الحقوق محفوظة © {new Date().getFullYear()} مسابقة أهل القرآن الكبرى
          </p>
          <div className="flex items-center gap-4 text-on-primary/25 text-xs font-bold">
            <a href="#" className="hover:text-secondary-fixed transition-colors">سياسة الخصوصية</a>
            <span className="w-1 h-1 rounded-full bg-white/10" />
            <a href="#" className="hover:text-secondary-fixed transition-colors">الشروط والأحكام</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
