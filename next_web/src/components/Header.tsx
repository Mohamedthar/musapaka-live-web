'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { Menu, X, ChevronDown, UserPlus } from 'lucide-react';

const navItems = [
  { href: '/', label: 'الرئيسية' },
  { href: '/levels', label: 'المستويات' },
  { href: '/register', label: 'تسجيل' },
];

const inquiryItems = [
  { href: '/status?tab=form', label: 'الاستعلام عن الاستمارة' },
  { href: '/status?tab=result', label: 'الاستعلام عن النتيجة' },
  { href: '/status?tab=ceremony', label: 'الاستعلام عن الحفل' },
];

export default function Header() {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [inquiryOpen, setInquiryOpen] = useState(false);
  const [mobileInquiryOpen, setMobileInquiryOpen] = useState(false);
  const inquiryRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => { queueMicrotask(() => { setMobileOpen(false); setMobileInquiryOpen(false); }); }, [pathname]);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (inquiryRef.current && !inquiryRef.current.contains(e.target as Node)) {
        setInquiryOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const isActive = (href: string) => {
    if (href === '/') return pathname === '/';
    const cleanHref = href.split('?')[0];
    return pathname === cleanHref || pathname.startsWith(cleanHref + '/');
  };
  const isInquiryActive = pathname.startsWith('/status');

  return (
    <motion.header
      initial={{ y: -30, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.5, ease: [0.25, 0.46, 0.45, 0.94] }}
      className={`sticky top-0 z-50 transition-all duration-500 ${
        scrolled
          ? 'bg-white/90 backdrop-blur-2xl shadow-lg shadow-black/5 border-b border-gray-100'
          : 'bg-white/70 backdrop-blur-md'
      }`}
    >
      <div className="flex items-center justify-between px-6 max-w-7xl mx-auto h-16">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2 shrink-0">
          <span
            className="font-black tracking-tight text-2xl md:text-3xl bg-gradient-to-l from-primary to-[#735c00] bg-clip-text text-transparent"
            style={{ fontFamily: "'Noto Serif', serif" }}
          >
            مسابقة أهل القرآن الكبرى
          </span>
        </Link>

        {/* Desktop Nav */}
        <nav className="hidden md:flex items-center gap-1">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`relative px-4 py-2 rounded-xl font-bold text-sm transition-all duration-300 ${
                isActive(item.href)
                  ? 'bg-primary/10 text-primary'
                  : 'text-gray-500 hover:bg-gray-100 hover:text-gray-800'
              }`}
            >
              {item.label}
              {isActive(item.href) && (
                <motion.div
                  layoutId="nav-indicator"
                  className="absolute bottom-0 left-2 right-2 h-0.5 bg-primary rounded-full"
                  transition={{ type: 'spring', stiffness: 500, damping: 35 }}
                />
              )}
            </Link>
          ))}

          {/* Inquiry Dropdown */}
          <div ref={inquiryRef} className="relative">
            <button
              onClick={() => setInquiryOpen(!inquiryOpen)}
              className={`relative flex items-center gap-1.5 px-4 py-2 rounded-xl font-bold text-sm transition-all duration-300 ${
                isInquiryActive
                  ? 'bg-primary/10 text-primary'
                  : 'text-gray-500 hover:bg-gray-100 hover:text-gray-800'
              } ${inquiryOpen ? 'bg-primary/10' : ''}`}
            >
              <span>الاستعلام</span>
              <motion.span
                animate={{ rotate: inquiryOpen ? 180 : 0 }}
                transition={{ duration: 0.2 }}
              >
                <ChevronDown size={14} />
              </motion.span>
              {isInquiryActive && (
                <motion.div
                  layoutId="nav-indicator"
                  className="absolute bottom-0 left-2 right-2 h-0.5 bg-primary rounded-full"
                  transition={{ type: 'spring', stiffness: 500, damping: 35 }}
                />
              )}
            </button>

            <AnimatePresence>
              {inquiryOpen && (
                <motion.div
                  initial={{ opacity: 0, y: 8, scale: 0.96 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: 8, scale: 0.96 }}
                  transition={{ duration: 0.15, ease: 'easeOut' }}
                  className="absolute top-full left-0 mt-2 w-64 bg-white border border-gray-100 rounded-2xl shadow-xl shadow-black/5 overflow-hidden"
                >
                  <div className="p-1.5">
                    {inquiryItems.map((item, i) => (
                      <Link
                        key={item.href}
                        href={item.href}
                        onClick={() => setInquiryOpen(false)}
                        className={`flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-bold transition-all duration-200 ${
                          isActive(item.href)
                            ? 'bg-primary/10 text-primary'
                            : 'text-gray-500 hover:bg-gray-50 hover:text-gray-800'
                        }`}
                      >
                        <span className="w-6 h-6 rounded-lg bg-primary/10 text-primary flex items-center justify-center text-[10px] font-black shrink-0">
                          {i + 1}
                        </span>
                        <span>{item.label}</span>
                      </Link>
                    ))}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </nav>

        {/* CTA + Mobile toggle */}
        <div className="flex items-center gap-3">
          <Link
            href="/register"
            className="hidden sm:inline-flex items-center gap-2 bg-primary text-white px-5 py-2 rounded-xl font-bold text-sm hover:bg-primary/90 active:scale-[0.97] transition-all duration-300 shadow-md shadow-primary/20 hover:shadow-lg hover:shadow-primary/30"
          >
            <UserPlus size={16} />
            سجل الآن
          </Link>
          <motion.button
            whileTap={{ scale: 0.9 }}
            className="md:hidden relative w-10 h-10 rounded-xl flex items-center justify-center bg-primary/10 text-primary hover:bg-primary/20 active:scale-95 transition-all duration-300"
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label="القائمة"
          >
            <AnimatePresence mode="wait">
              {mobileOpen ? (
                <motion.div key="x" initial={{ rotate: -90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: 90, opacity: 0 }} transition={{ duration: 0.2 }}>
                  <X size={22} />
                </motion.div>
              ) : (
                <motion.div key="menu" initial={{ rotate: 90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: -90, opacity: 0 }} transition={{ duration: 0.2 }}>
                  <Menu size={22} />
                </motion.div>
              )}
            </AnimatePresence>
          </motion.button>
        </div>
      </div>

      {/* Mobile Menu */}
      <AnimatePresence>
        {mobileOpen && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.3, ease: 'easeInOut' }}
            className="md:hidden overflow-hidden border-t border-gray-100 bg-white"
          >
            <nav className="flex flex-col gap-1 px-4 py-4">
              {navItems.map((item, i) => (
                <motion.div
                  key={item.href}
                  initial={{ opacity: 0, x: -16 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.05, duration: 0.25, ease: 'easeOut' }}
                >
                  <Link
                    href={item.href}
                    className={`block px-4 py-3 rounded-xl text-sm font-bold transition-all duration-200 ${
                      isActive(item.href)
                        ? 'bg-primary/10 text-primary'
                        : 'text-gray-500 hover:text-gray-800 hover:bg-gray-50'
                    }`}
                  >
                    {item.label}
                  </Link>
                </motion.div>
              ))}

              {/* Mobile Inquiry */}
              <motion.div
                initial={{ opacity: 0, x: -16 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: navItems.length * 0.05, duration: 0.25, ease: 'easeOut' }}
              >
                <button
                  onClick={() => setMobileInquiryOpen(!mobileInquiryOpen)}
                  className={`w-full flex items-center justify-between px-4 py-3 rounded-xl text-sm font-bold transition-all duration-200 ${
                    isInquiryActive
                      ? 'text-primary bg-primary/10'
                      : 'text-gray-500 hover:text-gray-800 hover:bg-gray-50'
                  }`}
                >
                  <span>الاستعلام</span>
                  <motion.span
                    animate={{ rotate: mobileInquiryOpen ? 180 : 0 }}
                    transition={{ duration: 0.2 }}
                  >
                    <ChevronDown size={16} />
                  </motion.span>
                </button>
                <AnimatePresence>
                  {mobileInquiryOpen && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.2, ease: 'easeInOut' }}
                      className="overflow-hidden mr-3"
                    >
                      {inquiryItems.map((item, idx) => (
                        <Link
                          key={item.href}
                          href={item.href}
                          className={`flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-bold transition-all duration-200 ${
                            isActive(item.href)
                              ? 'text-primary bg-primary/10'
                              : 'text-gray-500 hover:text-gray-800 hover:bg-gray-50'
                          }`}
                        >
                          <span className="w-6 h-6 rounded-lg bg-primary/10 text-primary flex items-center justify-center text-[10px] font-black shrink-0">
                            {idx + 1}
                          </span>
                          <span>{item.label}</span>
                        </Link>
                      ))}
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.25, duration: 0.2 }}
                className="mt-2 pt-3 border-t border-gray-100"
              >
                <Link
                  href="/register"
                  className="flex items-center justify-center gap-2 w-full py-3 bg-primary text-white rounded-xl font-bold text-sm hover:bg-primary/90 active:scale-[0.97] transition-all duration-200"
                >
                  <UserPlus size={18} />
                  سجل الآن
                </Link>
              </motion.div>
            </nav>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.header>
  );
}
