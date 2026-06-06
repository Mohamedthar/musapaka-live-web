'use client';

import React, { useEffect, useState, useSyncExternalStore } from 'react';
import { WifiOff, X } from 'lucide-react';
import { useOnline } from '@/hooks/useOnline';

function useMounted() {
  return useSyncExternalStore(
    () => () => {},
    () => true,
    () => false,
  );
}

export default function OfflineBanner() {
  const mounted = useMounted();
  const { online, wasOffline, dismiss } = useOnline();

  useEffect(() => {
    if (!online) {
      document.documentElement.style.setProperty('--online-banner-h', '40px');
    } else {
      document.documentElement.style.setProperty('--online-banner-h', '0px');
    }
    return () => {
      document.documentElement.style.setProperty('--online-banner-h', '0px');
    };
  }, [online]);

  if (!mounted) return null;

  return (
    <>
      {!online && (
        <div className="fixed top-0 inset-x-0 z-[9999] bg-red-600 text-white px-4 py-2.5 flex items-center justify-center gap-2 animate-slide-down shadow-lg">
          <WifiOff className="w-4 h-4 shrink-0" />
          <span className="text-sm font-semibold">أنت غير متصل بالإنترنت - قد لا تعمل بعض الميزات</span>
        </div>
      )}

      {online && wasOffline && (
        <div className="fixed top-0 inset-x-0 z-[9999] bg-green-600 text-white px-4 py-2.5 flex items-center justify-between animate-slide-down shadow-lg">
          <div className="flex items-center gap-2">
            <span className="text-sm font-semibold">✓ تم استعادة الاتصال بالإنترنت</span>
          </div>
          <button onClick={dismiss} className="p-0.5 hover:bg-white/10 rounded">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}
    </>
  );
}
