import type { Metadata } from "next";
import { Cairo, Noto_Serif } from "next/font/google";
import "material-symbols/outlined.css";
import "./globals.css";
import { Toaster } from 'react-hot-toast';

const cairo = Cairo({
  subsets: ["arabic", "latin"],
  variable: "--font-cairo",
  display: "swap",
  weight: ["300", "400", "500", "600", "700", "800", "900"],
});

const notoSerif = Noto_Serif({
  subsets: ["latin"],
  variable: "--font-noto-serif",
  display: "swap",
  weight: ["400", "600", "700", "800", "900"],
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
      <html lang="ar" dir="rtl" className="scroll-smooth">
        <head>
          <link rel="preload" href="/background.png" as="image" />
        </head>
        <body className={`${cairo.variable} ${notoSerif.variable} font-cairo antialiased`}>
        {children}
        <Toaster position="top-center" />
      </body>
    </html>
  );
}
