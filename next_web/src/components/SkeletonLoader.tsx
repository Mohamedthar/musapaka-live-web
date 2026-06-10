'use client';

export function CardSkeleton() {
  return (
    <div className="bg-white rounded-2xl border border-outline-variant p-5 animate-pulse">
      <div className="flex items-center gap-3 mb-4">
        <div className="w-10 h-10 rounded-xl bg-gray-100" />
        <div className="flex-1">
          <div className="h-4 bg-gray-100 rounded w-3/4 mb-2" />
          <div className="h-3 bg-gray-50 rounded w-1/2" />
        </div>
      </div>
      <div className="space-y-2">
        <div className="h-3 bg-gray-50 rounded w-full" />
        <div className="h-3 bg-gray-50 rounded w-5/6" />
        <div className="h-3 bg-gray-50 rounded w-4/6" />
      </div>
    </div>
  );
}

export function StatsSkeleton() {
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
      {[...Array(4)].map((_, i) => (
        <div key={i} className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 animate-pulse">
          <div className="h-8 bg-white/10 rounded w-1/2 mb-3" />
          <div className="h-5 bg-white/10 rounded w-3/4" />
        </div>
      ))}
    </div>
  );
}

export function LevelCardSkeleton() {
  return (
    <div className="bg-white rounded-2xl border border-outline-variant p-6 animate-pulse">
      <div className="flex items-center gap-3 mb-4">
        <div className="w-12 h-12 rounded-xl bg-gray-100" />
        <div className="flex-1">
          <div className="h-5 bg-gray-100 rounded w-2/3 mb-2" />
          <div className="h-3 bg-gray-50 rounded w-1/2" />
        </div>
      </div>
      <div className="space-y-2 mb-4">
        <div className="h-3 bg-gray-50 rounded w-full" />
        <div className="h-3 bg-gray-50 rounded w-4/5" />
      </div>
      <div className="flex gap-2">
        <div className="h-8 bg-gray-50 rounded-lg w-24" />
        <div className="h-8 bg-gray-50 rounded-lg w-24" />
      </div>
    </div>
  );
}

export function FormSkeleton() {
  return (
    <div className="space-y-6 animate-pulse">
      {[...Array(5)].map((_, i) => (
        <div key={i}>
          <div className="h-4 bg-gray-100 rounded w-1/4 mb-2" />
          <div className="h-12 bg-gray-50 rounded-xl w-full" />
        </div>
      ))}
      <div className="h-14 bg-gray-100 rounded-xl w-full" />
    </div>
  );
}
