'use client';

import { useState, useEffect, useCallback, useRef } from 'react';

export function useOnline() {
  const [online, setOnline] = useState(typeof navigator !== 'undefined' ? navigator.onLine : true);
  const [wasOffline, setWasOffline] = useState(false);
  const wasOfflineRef = useRef(false);

  useEffect(() => {
    const goOnline = () => {
      setOnline(true);
      if (wasOfflineRef.current) {
        setTimeout(() => setWasOffline(false), 3000);
      }
    };
    const goOffline = () => {
      setOnline(false);
      wasOfflineRef.current = true;
      setWasOffline(true);
    };

    window.addEventListener('online', goOnline);
    window.addEventListener('offline', goOffline);
    return () => {
      window.removeEventListener('online', goOnline);
      window.removeEventListener('offline', goOffline);
    };
  }, []);

  const dismiss = useCallback(() => {
    wasOfflineRef.current = false;
    setWasOffline(false);
  }, []);

  return { online, wasOffline, dismiss };
}
