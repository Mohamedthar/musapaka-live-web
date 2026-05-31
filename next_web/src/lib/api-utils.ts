import { NextResponse } from 'next/server';

const _KNOWN_ORIGINS = [
  'https://musapaka.vercel.app',
  'https://quran-contest-2026.vercel.app',
];

function getAllowedOrigins(): string[] {
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000';
  const vercelUrl = process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : null;
  return [siteUrl, vercelUrl, ..._KNOWN_ORIGINS].filter(Boolean) as string[];
}

export function getCorsHeaders(origin: string | null) {
  const allowed = getAllowedOrigins();
  const allowedOrigin = (origin && allowed.includes(origin)) ? origin : (allowed[0] || '');
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Vary': 'Origin',
  };
}

export function jsonResponse(data: unknown, status = 200, requestOrigin: string | null = null, cacheMaxAge?: number) {
  const headers: Record<string, string> = getCorsHeaders(requestOrigin ?? null);
  if (cacheMaxAge !== undefined) {
    headers['Cache-Control'] = `public, max-age=${cacheMaxAge}, stale-while-revalidate=${cacheMaxAge * 2}`;
  }
  return NextResponse.json(data, {
    status,
    headers,
  });
}

export function optionsResponse(request: Request) {
  const origin = request.headers.get('origin');
  return new NextResponse(null, { status: 204, headers: getCorsHeaders(origin) });
}

const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
let lastCleanup = Date.now();

export function checkRateLimit(ip: string, maxRequests = 5, windowMs = 60_000): boolean {
  const now = Date.now();
  if (now - lastCleanup > windowMs) {
    for (const [key, val] of rateLimitMap.entries()) {
      if (now > val.resetAt) rateLimitMap.delete(key);
    }
    lastCleanup = now;
  }
  const entry = rateLimitMap.get(ip);
  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(ip, { count: 1, resetAt: now + windowMs });
    return true;
  }
  if (entry.count >= maxRequests) return false;
  entry.count++;
  return true;
}

export function getClientIp(request: Request): string {
  return (
    request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
    'unknown'
  );
}

export function validateCsrf(request: Request): boolean {
  const origin = request.headers.get('origin');
  const referer = request.headers.get('referer');

  if (!origin && !referer) return false;

  if (origin) {
    return getAllowedOrigins().some((allowed) => origin.startsWith(allowed));
  }

  if (referer) {
    return getAllowedOrigins().some((allowed) => referer.startsWith(allowed));
  }

  return false;
}
