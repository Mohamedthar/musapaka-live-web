'use client';

import React from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';

const navLinks = [
  { href: '/register', label: 'التسجيل' },
  { href: '/levels', label: 'المستويات' },
  { href: '/status', label: 'الاستعلام' },
  { href: '/status?tab=result', label: 'النتائج' },
];

const phones = ['01065502096', '01023240169', '01062114225'];

const socialLinks = [
  {
    href: 'https://www.facebook.com/share/1AwxWEQwSV/',
    label: 'فيسبوك',
    icon: (
      <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
        <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
      </svg>
    ),
  },
  {
    href: 'https://maps.app.goo.gl/AxtZbB5Jb3Lcy9BT7',
    label: 'موقع اللجنة',
    icon: (
      <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0Z"/>
        <circle cx="12" cy="10" r="3"/>
      </svg>
    ),
  },
];

export default function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="w-full bg-gradient-to-b from-[#002117] to-[#003527] text-white relative overflow-hidden" dir="rtl">
      <div className="absolute inset-0 islamic-pattern z-0 opacity-[0.03]" />

      <div className="relative z-10 max-w-6xl mx-auto px-6 py-12 lg:py-16">
        {/* Top decorative line */}
        <motion.div
          className="w-16 h-[2px] bg-secondary-fixed/70 mx-auto mb-10 rounded-full"
          initial={{ width: 0, opacity: 0 }}
          whileInView={{ width: 64, opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        />

        {/* Main content */}
        <div className="grid grid-cols-2 md:grid-cols-12 gap-6 md:gap-6">
          {/* Brand - full width on all screens */}
          <motion.div
            className="col-span-2 md:col-span-12 lg:col-span-5 flex flex-col items-center text-center gap-3"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
          >
            <h3
              className="text-2xl lg:text-3xl font-black text-secondary-fixed"
              style={{ fontFamily: "'Noto Serif', serif" }}
            >
              مسابقة أهل القرآن الكبرى
            </h3>
            <p className="text-white/40 text-sm lg:text-base leading-[1.8] max-w-sm">
              منصة مخصصة لمسابقة أهل القرآن الكريم الكبرى في الديدامون مركز فاقوس تحت إشراف الشيخ <span className="text-secondary-fixed font-bold">مصطفى عبدالرحمن</span>
            </p>
          </motion.div>

          {/* Spacer for lg */}
          <div className="hidden lg:block lg:col-span-1" />

          {/* Links - 1 col on mobile, 4 on md, 2 on lg */}
          <motion.div
            className="col-span-1 md:col-span-4 lg:col-span-2 flex flex-col items-center text-center gap-3"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1], delay: 0.1 }}
          >
            <h5 className="text-white/60 font-bold text-xs tracking-widest uppercase">
              المنصة
            </h5>
            <div className="flex flex-col items-center gap-2">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className="text-white/40 hover:text-secondary-fixed transition-colors text-sm font-bold"
                >
                  {link.label}
                </Link>
              ))}
            </div>
          </motion.div>

          {/* Contact - 1 col on mobile, 4 on md, 2 on lg */}
          <motion.div
            className="col-span-1 md:col-span-4 lg:col-span-2 flex flex-col items-center text-center gap-3"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1], delay: 0.2 }}
          >
            <h5 className="text-white/60 font-bold text-xs tracking-widest uppercase">
              للاستفسار
            </h5>
            <div className="flex flex-col items-center gap-2">
              {phones.map((phone) => (
                <a
                  key={phone}
                  href={`https://wa.me/20${phone.replace(/^0/, '')}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group text-white/40 hover:text-secondary-fixed transition-colors text-sm font-bold flex items-center gap-2"
                  dir="ltr"
                >
                  <span className="w-5 h-5 rounded bg-secondary-fixed/10 flex items-center justify-center text-secondary-fixed/70 shrink-0">
                    <svg className="w-3 h-3" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
                  </span>
                  {phone}
                </a>
              ))}
            </div>
          </motion.div>

          {/* Social - full width on mobile, 4 on md, 2 on lg */}
          <motion.div
            className="col-span-2 md:col-span-4 lg:col-span-2 flex flex-col items-center text-center gap-3"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1], delay: 0.3 }}
          >
            <h5 className="text-white/60 font-bold text-xs tracking-widest uppercase">
              روابط
            </h5>
            <div className="flex flex-row md:flex-col items-center justify-center gap-4 md:gap-2">
              {socialLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group text-white/40 hover:text-secondary-fixed transition-colors text-sm font-bold flex items-center gap-2"
                >
                  <span className="w-5 h-5 rounded bg-secondary-fixed/10 flex items-center justify-center text-secondary-fixed/70 shrink-0">
                    {link.icon}
                  </span>
                  <span>{link.label}</span>
                </a>
              ))}
            </div>
          </motion.div>
        </div>

        {/* Divider */}
        <motion.div
          className="mt-10 border-t border-white/[0.04]"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.4 }}
        />

        {/* Copyright */}
        <motion.div
          className="pt-6 flex justify-center"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.5 }}
        >
          <p className="text-white/15 text-[10px] font-bold tracking-widest">
            جميع الحقوق محفوظة &copy; {year} مسابقة أهل القرآن الكبرى
          </p>
        </motion.div>
      </div>
    </footer>
  );
}
