'use client';

export default function Error({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-surface p-4" dir="rtl">
      <div className="text-center max-w-md">
        <div className="w-16 h-16 bg-error-container rounded-full flex items-center justify-center mx-auto mb-4">
          <span className="text-error text-2xl font-bold">!</span>
        </div>
        <h1 className="text-xl font-bold text-on-surface mb-2">حدث خطأ غير متوقع</h1>
        <p className="text-sm text-on-surface-variant mb-6">
          نعتذر عن هذا الخطأ. يرجى المحاولة مرة أخرى.
        </p>
        <button
          onClick={reset}
          className="px-6 py-2.5 bg-primary text-on-primary rounded-xl font-bold text-sm hover:bg-primary-container active:scale-95 transition-all"
        >
          إعادة المحاولة
        </button>
      </div>
    </div>
  );
}
