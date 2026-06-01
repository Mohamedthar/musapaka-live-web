import { CardSkeleton, StatsSkeleton } from '@/components/SkeletonLoader';

export default function Loading() {
  return (
    <div className="min-h-screen bg-surface" dir="rtl">
      <div className="h-20 bg-white border-b border-outline-variant animate-pulse" />

      <section className="bg-primary min-h-[50vh] flex flex-col items-center justify-center px-4 py-16">
        <div className="w-20 h-20 rounded-2xl bg-white/10 mb-6 animate-pulse" />
        <div className="h-12 bg-white/10 rounded w-64 mb-4 animate-pulse" />
        <div className="h-4 bg-white/5 rounded w-48 animate-pulse" />
        <div className="mt-8 w-full max-w-4xl">
          <StatsSkeleton />
        </div>
      </section>

      <section className="max-w-6xl mx-auto px-4 py-16">
        <div className="text-center mb-10">
          <div className="h-8 bg-gray-100 rounded w-48 mx-auto mb-2 animate-pulse" />
          <div className="h-4 bg-gray-50 rounded w-64 mx-auto animate-pulse" />
        </div>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <CardSkeleton key={i} />
          ))}
        </div>
      </section>
    </div>
  );
}
