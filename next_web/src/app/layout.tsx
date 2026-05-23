import type { Metadata } from "next";
import { Cairo } from "next/font/google";
import "./globals.css";
import { Toaster } from 'react-hot-toast';

const cairo = Cairo({
  subsets: ["arabic", "latin"],
  variable: "--font-cairo",
  display: "swap",
  weight: ["300", "400", "500", "600", "700", "800", "900"],
});

export const metadata: Metadata = {
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
    <html lang="ar" dir="rtl" data-scroll-behavior="smooth">
      <body className={`${cairo.variable} font-cairo antialiased bg-white min-h-screen text-[var(--text-primary)]`}>
        {children}
        <Toaster position="top-center" />
      </body>
    </html>
  );
}
