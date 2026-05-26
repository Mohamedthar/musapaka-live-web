import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-surface p-4" dir="rtl">
      <div className="text-center max-w-md">
        <div className="text-6xl font-black text-primary mb-4">404</div>
        <h1 className="text-xl font-bold text-on-surface mb-2">الصفحة غير موجودة</h1>
        <p className="text-sm text-on-surface-variant mb-6">
          الصفحة التي تبحث عنها غير موجودة أو تم نقلها.
        </p>
        <Link
          href="/"
          className="inline-block px-6 py-2.5 bg-primary text-on-primary rounded-xl font-bold text-sm hover:bg-primary-container active:scale-95 transition-all"
        >
          العودة للرئيسية
        </Link>
      </div>
    </div>
  );
}
