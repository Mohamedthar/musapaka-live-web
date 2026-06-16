import { NextResponse } from 'next/server';

function getAllowedOrigins(): string[] {
  const siteUrl = (process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000').replace(/\/+$/, '');
  const extraOrigins = (process.env.EXTRA_CORS_ORIGINS || '').split(',').map(s => s.trim()).filter(Boolean);
  const localhostOrigins = ['http://localhost:3000', 'http://localhost:3001'];
  return [...new Set([siteUrl, ...extraOrigins, ...localhostOrigins].filter(Boolean))] as string[];
}

function originMatches(allowed: string, origin: string): boolean {
  try {
    const a = new URL(allowed);
    const o = new URL(origin);
    return a.hostname === o.hostname && a.protocol === o.protocol && a.port === o.port;
  } catch {
    return allowed === origin;
  }
}

export function getCorsHeaders(origin: string | null) {
  const allowed = getAllowedOrigins();
  const allowedOrigin = (origin && allowed.some((a) => originMatches(a, origin))) ? origin : (allowed[0] || '');
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Vary': 'Origin',
  };
}

export function jsonResponse(data: unknown, status = 200, requestOrigin: string | null = null, cacheMaxAge?: number) {
  const headers: Record<string, string> = getCorsHeaders(requestOrigin ?? null);
  if (cacheMaxAge !== undefined && cacheMaxAge > 0) {
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

export function clearRateLimitsForTesting(): void {
  rateLimitMap.clear();
  lastCleanup = Date.now();
}

export function getClientIp(request: Request): string {
  const cf = request.headers.get('cf-connecting-ip');
  if (cf) return cf;
  const xRealIp = request.headers.get('x-real-ip');
  if (xRealIp) return xRealIp;
  const xff = request.headers.get('x-forwarded-for');
  if (xff) {
    const parts = xff.split(',').map(s => s.trim()).filter(Boolean);
    if (parts.length > 0) return parts[0];
  }
  return 'unknown';
}

export function validateCsrf(request: Request): boolean {
  const origin = request.headers.get('origin');
  const referer = request.headers.get('referer');
  const host = request.headers.get('host') || '';

  if (!origin && !referer) return false;

  // Allow same-origin requests (Origin matches Host) — covers Vercel preview deployments
  if (origin && host) {
    try {
      const originHost = new URL(origin).hostname;
      const requestHost = host.split(':')[0];
      if (originHost === requestHost) return true;
    } catch { /* fall through to allowed origins check */ }
  }

  const allowed = getAllowedOrigins();

  // Also allow all Vercel preview deployments (*.vercel.app)
  if (origin) {
    try {
      const originHost = new URL(origin).hostname;
      if (originHost.endsWith('.vercel.app')) return true;
    } catch { /* fall through */ }
    return allowed.some((a) => originMatches(a, origin));
  }

  if (referer) {
    return allowed.some((a) => {
      try {
        const r = new URL(referer);
        const al = new URL(a);
        return r.hostname === al.hostname && r.protocol === al.protocol && r.port === al.port;
      } catch {
        return referer.startsWith(a);
      }
    });
  }

  return false;
}
