'use client';

import { useState, useEffect, useCallback } from 'react';

export function useOnline() {
  const [online, setOnline] = useState(true);
  const [wasOffline, setWasOffline] = useState(false);

  useEffect(() => {
    const goOnline = () => {
      setOnline(true);
      if (wasOffline) setTimeout(() => setWasOffline(false), 3000);
    };
    const goOffline = () => {
      setOnline(false);
      setWasOffline(true);
    };

    setOnline(navigator.onLine);
    window.addEventListener('online', goOnline);
    window.addEventListener('offline', goOffline);
    return () => {
      window.removeEventListener('online', goOnline);
      window.removeEventListener('offline', goOffline);
    };
  }, [wasOffline]);

  const dismiss = useCallback(() => setWasOffline(false), []);

  return { online, wasOffline, dismiss };
}
