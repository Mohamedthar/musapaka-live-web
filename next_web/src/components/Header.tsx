'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { Menu, X, ChevronDown } from 'lucide-react';

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
  const inquiryRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  useEffect(() => { setMobileOpen(false); }, [pathname]);

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
      className={`sticky top-0 z-50 transition-all duration-500 py-3 ${
        scrolled
          ? 'bg-surface/85 backdrop-blur-2xl shadow-lg shadow-black/5 border-b border-outline-variant/20'
          : 'bg-surface/70 backdrop-blur-md'
      }`}
    >
      <div className="flex flex-row justify-between items-center px-6 max-w-7xl mx-auto">
        {/* Logo — right side */}
        <Link
          href="/"
          className="flex items-center gap-2 group"
        >
          <motion.span
            className="font-black text-secondary tracking-tight text-2xl md:text-[28px]"
            style={{ fontFamily: "'Noto Serif', serif" }}
            whileHover={{ scale: 1.02 }}
          >
            مسابقة أهل القرآن الكبرى
          </motion.span>
          <div className="w-1.5 h-1.5 rounded-full bg-secondary-fixed-dim opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
        </Link>

        {/* Desktop Links — center/left */}
        <nav className="hidden md:flex items-center gap-1.5">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`relative px-4 py-2 rounded-xl font-bold text-sm transition-all duration-300 ${
                isActive(item.href)
                  ? 'text-secondary bg-secondary/8'
                  : 'text-on-surface-variant hover:text-secondary hover:bg-secondary/5'
              }`}
            >
              {item.label}

              {isActive(item.href) && (
                <motion.div
                  layoutId="nav-indicator"
                  className="absolute bottom-0 left-2 right-2 h-0.5 bg-secondary rounded-full"
                  transition={{ type: 'spring', stiffness: 500, damping: 35 }}
                />
              )}
            </Link>
          ))}

          {/* Inquiry Dropdown */}
          <div ref={inquiryRef} className="relative">
            <button
              onClick={() => setInquiryOpen(!inquiryOpen)}
              onMouseEnter={() => setInquiryOpen(true)}
              className={`relative flex items-center gap-1.5 px-4 py-2 rounded-xl font-bold text-sm transition-all duration-300 ${
                isInquiryActive
                  ? 'text-secondary bg-secondary/8'
                  : 'text-on-surface-variant hover:text-secondary hover:bg-secondary/5'
              }`}
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
                  className="absolute bottom-0 left-2 right-2 h-0.5 bg-secondary rounded-full"
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
                  onMouseLeave={() => setInquiryOpen(false)}
                  className="absolute top-full left-0 mt-2 w-64 bg-surface border border-outline-variant/20 rounded-2xl shadow-xl shadow-black/5 overflow-hidden backdrop-blur-2xl"
                >
                  {inquiryItems.map((item, i) => (
                    <Link
                      key={item.href}
                      href={item.href}
                      onClick={() => setInquiryOpen(false)}
                      className={`flex items-center gap-3 px-5 py-3.5 text-sm font-bold transition-all duration-200 ${
                        isActive(item.href)
                          ? 'text-secondary bg-secondary/8'
                          : 'text-on-surface-variant hover:text-secondary hover:bg-secondary/5'
                      } ${i < inquiryItems.length - 1 ? 'border-b border-outline-variant/10' : ''}`}
                    >
                      <span>{item.label}</span>
                    </Link>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </nav>

        {/* CTA + Mobile toggle — left side */}
        <div className="flex items-center gap-3">
          <Link
            href="/register"
            className="hidden sm:inline-flex items-center gap-2 bg-primary text-on-primary px-5 py-2 rounded-xl font-bold text-sm hover:bg-primary-container active:scale-[0.97] transition-all duration-300 shadow-md shadow-primary/10 hover:shadow-lg hover:shadow-primary/20">
            <span className="material-symbols-outlined text-[16px]">person_add</span>
            سجل الآن
          </Link>
          <motion.button
            whileTap={{ scale: 0.9 }}
            className="md:hidden relative w-10 h-10 rounded-xl flex items-center justify-center text-on-surface-variant hover:text-secondary hover:bg-secondary/10 transition-all duration-200"
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
            className="md:hidden overflow-hidden border-t border-outline-variant/20 bg-surface/98 backdrop-blur-2xl"
          >
            <nav className="flex flex-col gap-1 px-6 py-4">
              {navItems.map((item, i) => (
                <motion.div
                  key={item.href}
                  initial={{ opacity: 0, x: -16 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.05, duration: 0.25, ease: 'easeOut' }}
                >
                  <Link
                    href={item.href}
                    className={`block px-4 py-3.5 rounded-xl text-sm font-bold transition-all duration-200 ${
                      isActive(item.href)
                        ? 'bg-secondary/10 text-secondary'
                        : 'text-on-surface-variant hover:text-secondary hover:bg-secondary/5'
                    }`}
                  >
                    {item.label}
                  </Link>
                </motion.div>
              ))}

              {/* Mobile Inquiry Section */}
              <motion.div
                initial={{ opacity: 0, x: -16 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: navItems.length * 0.05, duration: 0.25, ease: 'easeOut' }}
              >
                <div className="px-4 pt-4 pb-1 text-[11px] font-bold text-on-surface-variant/50 tracking-wider">
                  الاستعلام
                </div>
                {inquiryItems.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`block px-4 py-3.5 rounded-xl text-sm font-bold transition-all duration-200 ${
                      isActive(item.href)
                        ? 'bg-secondary/10 text-secondary'
                        : 'text-on-surface-variant hover:text-secondary hover:bg-secondary/5'
                    }`}
                  >
                    {item.label}
                  </Link>
                ))}
              </motion.div>
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.25, duration: 0.2 }}
                className="mt-2 pt-3 border-t border-outline-variant/10"
              >
                <Link
                  href="/register"
                  className="flex items-center justify-center gap-2 w-full py-3 bg-primary text-on-primary rounded-xl font-bold text-sm hover:bg-primary-container active:scale-[0.97] transition-all duration-200"
                >
                  <span className="material-symbols-outlined text-[18px]">person_add</span>
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
