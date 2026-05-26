export default function Loading() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-surface" dir="rtl">
      <div className="text-center">
        <div className="w-12 h-12 border-4 border-outline-variant border-t-primary rounded-full animate-spin mx-auto mb-4" />
        <p className="text-sm text-on-surface-variant font-semibold">جاري التحميل...</p>
      </div>
    </div>
  );
}
