import { CardSkeleton } from '@/components/SkeletonLoader';

export default function Loading() {
  return (
    <div className="min-h-screen bg-surface" dir="rtl">
      <div className="h-16 bg-white border-b border-outline-variant animate-pulse" />

      <section className="bg-primary min-h-[60vh] flex flex-col items-center justify-center px-4 py-16">
        <div className="h-12 bg-white/10 rounded w-64 mb-4 animate-pulse" />
        <div className="h-4 bg-white/5 rounded w-48 animate-pulse" />
        <div className="mt-8 flex gap-3">
          <div className="h-10 bg-white/10 rounded-xl w-32 animate-pulse" />
          <div className="h-10 bg-white/5 rounded-xl w-44 animate-pulse" />
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4 py-16">
        <div className="text-center mb-10">
          <div className="h-8 bg-gray-100 rounded w-48 mx-auto mb-2 animate-pulse" />
          <div className="h-4 bg-gray-50 rounded w-64 mx-auto animate-pulse" />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-5">
          {[...Array(5)].map((_, i) => (
            <CardSkeleton key={i} />
          ))}
        </div>
      </section>
    </div>
  );
}
