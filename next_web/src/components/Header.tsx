'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { UserPlus, Award, ChevronDown, Menu, X, FileText, CalendarCheck, Home, BookOpen } from 'lucide-react';

interface HeaderProps {
  activeSection?: string;
}

export default function Header({}: HeaderProps) {
  const [inquiryDropdownOpen, setInquiryDropdownOpen] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [mobileInquiryOpen, setMobileInquiryOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 bg-white/95 backdrop-blur-md border-b border-[var(--border-light)] transition-all duration-200">
      <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
        
        {/* Logo and Branding */}
        <Link href="/" className="flex items-center gap-3 group">
          <div className="w-10 h-10 rounded-full overflow-hidden flex items-center justify-center bg-white p-0.5 border border-[var(--border)] transition-all duration-300 group-hover:border-[var(--beige)] flex-shrink-0">
            <Image 
              src="/logo_musapaka.jpeg" 
              alt="شعار مسابقة القرآن الكريم" 
              width={40} 
              height={40} 
              className="object-cover w-full h-full rounded-full" 
            />
          </div>
          <div className="text-right">
            <span className="font-extrabold text-sm sm:text-base block tracking-tight text-[var(--primary)]">
              مسابقة القرآن الكريم
            </span>
            <span className="text-[8px] sm:text-[9px] text-[var(--text-muted)] font-bold block -mt-1 tracking-wider">
              بالديدامون والحيدامون
            </span>
          </div>
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center gap-7 text-xs font-black text-[var(--text-secondary)]">
          <Link href="/" className="hover:text-[var(--primary)] transition-colors duration-150 flex items-center gap-1.5 py-2">
            <Home size={14} className="text-[var(--text-muted)]" />
            <span>الرئيسية</span>
          </Link>
          
          <Link href="/levels" className="hover:text-[var(--primary)] transition-colors duration-150 flex items-center gap-1.5 py-2">
            <BookOpen size={14} className="text-[var(--text-muted)]" />
            <span>المستويات والجوائز</span>
          </Link>

          <Link href="/register" className="hover:text-[var(--primary)] transition-colors duration-150 flex items-center gap-1.5 py-2">
            <UserPlus size={14} className="text-[var(--text-muted)]" />
            <span>تسجيل متسابق</span>
          </Link>

          {/* Inquiry Dropdown */}
          <div className="relative">
            <button
              onClick={() => setInquiryDropdownOpen(!inquiryDropdownOpen)}
              onMouseEnter={() => setInquiryDropdownOpen(true)}
              className="flex items-center gap-1.5 hover:text-[var(--primary)] transition-colors duration-150 py-2 focus:outline-none"
            >
              <FileText size={14} className="text-[var(--text-muted)]" />
              <span>بوابة الاستعلامات</span>
              <ChevronDown size={13} className={`transition-transform duration-200 ${inquiryDropdownOpen ? 'rotate-180 text-[var(--primary)]' : 'text-[var(--text-muted)]'}`} />
            </button>

            {inquiryDropdownOpen && (
              <div 
                onMouseLeave={() => setInquiryDropdownOpen(false)}
                className="absolute right-0 mt-1 w-56 bg-white border border-[var(--border)] rounded-xl shadow-lg p-1.5 space-y-0.5 animate-fade-in text-right z-50"
              >
                <Link 
                  href="/status?tab=result"
                  onClick={() => setInquiryDropdownOpen(false)}
                  className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-[var(--beige-light)] text-[var(--text-secondary)] hover:text-[var(--primary)] transition-all font-bold text-xs"
                >
                  <span className="w-7 h-7 rounded-md bg-[var(--beige-light)] flex items-center justify-center text-[var(--beige-dark)] border border-[var(--border)]"><Award size={14} /></span>
                  <span>الاستعلام عن النتيجة</span>
                </Link>
                <Link 
                  href="/status?tab=ceremony"
                  onClick={() => setInquiryDropdownOpen(false)}
                  className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-[var(--beige-light)] text-[var(--text-secondary)] hover:text-[var(--primary)] transition-all font-bold text-xs"
                >
                  <span className="w-7 h-7 rounded-md bg-[var(--beige-light)] flex items-center justify-center text-[var(--beige-dark)] border border-[var(--border)]"><CalendarCheck size={14} /></span>
                  <span>الاستعلام عن حضور الحفل</span>
                </Link>
                <Link 
                  href="/status"
                  onClick={() => setInquiryDropdownOpen(false)}
                  className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-[var(--beige-light)] text-[var(--text-secondary)] hover:text-[var(--primary)] transition-all font-bold text-xs"
                >
                  <span className="w-7 h-7 rounded-md bg-[var(--beige-light)] flex items-center justify-center text-[var(--beige-dark)] border border-[var(--border)]"><FileText size={14} /></span>
                  <span>الاستعلام عن الاستمارة</span>
                </Link>
              </div>
            )}
          </div>
        </nav>

        {/* Action Button & Mobile Toggle */}
        <div className="flex items-center gap-3">
          <Link href="/register" className="hidden sm:flex items-center gap-2 btn-primary px-4 py-2.5 text-xs font-bold shadow-sm">
            <UserPlus size={14} />
            <span>تسجيل جديد</span>
          </Link>
          <button 
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 text-[var(--text-primary)] hover:bg-[var(--bg-section)] transition-colors focus:outline-none rounded-lg border border-[var(--border)]"
          >
            {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t border-[var(--border)] bg-white p-4 animate-slide-down text-right shadow-lg absolute left-0 right-0 w-full z-50">
          <div className="space-y-1">
            <Link 
              href="/" 
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-[var(--text-secondary)] hover:text-[var(--primary)] font-bold text-xs hover:bg-[var(--beige-light)] transition-all duration-200 group"
            >
              <span className="w-8 h-8 rounded-full bg-[var(--beige-light)] border border-[var(--border)] overflow-hidden flex-shrink-0 flex items-center justify-center">
                <Image src="/logo_musapaka.jpeg" alt="" width={20} height={20} className="object-cover w-5 h-5 rounded-full" />
              </span>
              <span>الشاشة الرئيسية</span>
            </Link>
            
            <Link 
              href="/levels" 
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-[var(--text-secondary)] hover:text-[var(--primary)] font-bold text-xs hover:bg-[var(--beige-light)] transition-all duration-200 group"
            >
              <span className="w-8 h-8 rounded-lg bg-[var(--beige-light)] border border-[var(--border)] flex items-center justify-center text-[var(--beige-dark)]">
                <BookOpen size={14} />
              </span>
              <span>المستويات والجوائز</span>
            </Link>
            
            <Link 
              href="/register" 
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-[var(--text-secondary)] hover:text-[var(--primary)] font-bold text-xs hover:bg-[var(--beige-light)] transition-all duration-200 group"
            >
              <span className="w-8 h-8 rounded-lg bg-[var(--beige-light)] border border-[var(--border)] flex items-center justify-center text-[var(--beige-dark)]">
                <UserPlus size={14} />
              </span>
              <span>تسجيل متسابق</span>
            </Link>
            
            <button
              onClick={() => setMobileInquiryOpen(!mobileInquiryOpen)}
              className={`w-full flex items-center justify-between px-3 py-2.5 rounded-xl transition-all duration-200 font-bold text-xs ${mobileInquiryOpen ? 'bg-[var(--beige-light)] text-[var(--primary)]' : 'text-[var(--text-secondary)] hover:text-[var(--primary)] hover:bg-[var(--beige-light)]'}`}
            >
              <span className="flex items-center gap-3">
                <span className={`w-8 h-8 rounded-lg border flex items-center justify-center transition-colors ${mobileInquiryOpen ? 'bg-white border-[var(--beige)] text-[var(--beige-dark)]' : 'bg-[var(--beige-light)] border-[var(--border)] text-[var(--beige-dark)]'}`}>
                  <FileText size={14} />
                </span>
                <span>بوابة الاستعلام الإلكتروني</span>
              </span>
              <ChevronDown size={14} className={`transition-transform duration-200 ${mobileInquiryOpen ? 'rotate-180 text-[var(--primary)]' : 'text-[var(--text-muted)]'}`} />
            </button>
            
            {mobileInquiryOpen && (
              <div className="mt-1 mx-1 bg-white border border-[var(--border)] p-1.5 rounded-xl space-y-0.5 animate-fade-in">
                <Link 
                  href="/status?tab=result" 
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-center gap-3 px-3 py-2 rounded-lg text-[var(--text-secondary)] hover:text-[var(--primary)] font-bold text-[11px] hover:bg-[var(--beige-light)] transition-all duration-200"
                >
                  <span className="flex items-center justify-center w-5 h-5 text-[var(--beige-dark)]"><Award size={14} /></span>
                  <span>الاستعلام عن النتيجة</span>
                </Link>
                <Link 
                  href="/status?tab=ceremony" 
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-center gap-3 px-3 py-2 rounded-lg text-[var(--text-secondary)] hover:text-[var(--primary)] font-bold text-[11px] hover:bg-[var(--beige-light)] transition-all duration-200"
                >
                  <span className="flex items-center justify-center w-5 h-5 text-[var(--beige-dark)]"><CalendarCheck size={14} /></span>
                  <span>الاستعلام عن حضور الحفل</span>
                </Link>
                <Link 
                  href="/status" 
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-center gap-3 px-3 py-2 rounded-lg text-[var(--text-secondary)] hover:text-[var(--primary)] font-bold text-[11px] hover:bg-[var(--beige-light)] transition-all duration-200"
                >
                  <span className="flex items-center justify-center w-5 h-5 text-[var(--beige-dark)]"><FileText size={14} /></span>
                  <span>الاستعلام عن الاستمارة</span>
                </Link>
              </div>
            )}

            {/* Quick Action in Mobile */}
            <div className="pt-2 pb-0.5 border-t border-[var(--border)]">
              <Link 
                href="/register" 
                onClick={() => setMobileMenuOpen(false)}
                className="w-full flex items-center justify-center gap-2 btn-primary py-2.5 text-xs font-bold"
              >
                <UserPlus size={14} />
                <span>تسجيل جديد الآن</span>
              </Link>
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
