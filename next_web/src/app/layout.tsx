import type { Metadata } from "next";
import { Cairo, Noto_Serif } from "next/font/google";
import { Suspense } from "react";
import "./globals.css";
import { Toaster } from 'react-hot-toast';
import OfflineBanner from '@/components/OfflineBanner';

const cairo = Cairo({
  subsets: ["arabic"],
  variable: "--font-cairo",
  display: "swap",
  weight: ["600", "700", "900"],
  preload: true,
});

const notoSerif = Noto_Serif({
  subsets: ["latin"],
  variable: "--font-noto-serif",
  display: "swap",
  weight: ["700", "900"],
  preload: false,
});

export const metadata: Metadata = {
  metadataBase: new URL('https://musapaka.com'),
  title: "مسابقة القرآن الكريم",
  description: "الموقع الرسمي للتسجيل في مسابقة القرآن الكريم",
  icons: {
    icon: "/logo_musapaka.jpeg",
    apple: "/logo_musapaka.jpeg",
  },
  openGraph: {
    title: "مسابقة القرآن الكريم",
    description: "الموقع الرسمي للتسجيل في مسابقة القرآن الكريم",
    images: [{ url: "/logo_musapaka.jpeg" }],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
      <html lang="ar" dir="rtl" className="scroll-smooth" data-scroll-behavior="smooth">
        <head>
          <link rel="preload" href="/background.png" as="image" />
          <link rel="preconnect" href="https://fvwpmbqbporgvxmfbjla.supabase.co" crossOrigin="anonymous" />
          <link rel="preconnect" href="https://res.cloudinary.com" crossOrigin="anonymous" />
          <link rel="preconnect" href="https://api.qrserver.com" crossOrigin="anonymous" />
          <link rel="dns-prefetch" href="https://fvwpmbqbporgvxmfbjla.supabase.co" />
          <link rel="dns-prefetch" href="https://res.cloudinary.com" />
        </head>
        <body className={`${cairo.variable} ${notoSerif.variable} font-cairo antialiased`}>
        <OfflineBanner />
        <div className="pt-[var(--online-banner-h,0px)] transition-[padding] duration-300">
          <Suspense fallback={
            <div className="min-h-screen flex items-center justify-center bg-surface">
              <div className="w-10 h-10 border-3 border-primary/25 border-t-primary rounded-full animate-spin" />
            </div>
          }>
            {children}
          </Suspense>
        </div>
        <Toaster position="top-center" />
      </body>
    </html>
  );
}
