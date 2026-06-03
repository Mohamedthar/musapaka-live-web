import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const RATE_LIMIT = 30;
const WINDOW_MS = 60_000;
const CLEANUP_INTERVAL_MS = 120_000;

const rateLimitStore = new Map<string, { count: number; resetAt: number }>();
let lastCleanup = Date.now();

const BOT_PATTERNS = [
  /zgrab/i, /sqlmap/i, /nikto/i, /nmap/i, /masscan/i,
  /nessus/i, /acunetix/i, /burpsuite/i, /dirbuster/i, /gobuster/i,
  /hydra/i, /metasploit/i, /openvas/i, /w3af/i, /whatweb/i,
  /webscarab/i, /netsparker/i, /appscan/i, /arachni/i, /skipfish/i,
  /headless/i, /scanner/i, /crawler/i,
];

function isBot(ua: string): boolean {
  if (!ua) return false;

  const knownGood = /googlebot|bingbot|duckduckbot|baiduspider|yandex|slurp|twitterbot|facebookexternalhit/i;
  if (knownGood.test(ua)) return false;

  return BOT_PATTERNS.some((p) => p.test(ua));
}

function cleanupRateLimitStore() {
  const now = Date.now();
  if (now - lastCleanup < CLEANUP_INTERVAL_MS) return;
  lastCleanup = now;
  for (const [key, val] of rateLimitStore.entries()) {
    if (now > val.resetAt) rateLimitStore.delete(key);
  }
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (pathname.startsWith('/api/')) {
    const ua = request.headers.get('user-agent') || '';
    if (isBot(ua)) {
      return new NextResponse('Forbidden', { status: 403 });
    }

    const ip = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || 'unknown';

    if (ip !== 'unknown') {
      cleanupRateLimitStore();
      const now = Date.now();
      const entry = rateLimitStore.get(ip);

      if (!entry || now > entry.resetAt) {
        rateLimitStore.set(ip, { count: 1, resetAt: now + WINDOW_MS });
      } else {
        entry.count++;
        if (entry.count > RATE_LIMIT) {
          return new NextResponse('Too Many Requests', { status: 429 });
        }
      }
    }
  }

  const response = NextResponse.next();
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('X-Frame-Options', 'DENY');
  return response;
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.svg|.*\\.png|.*\\.jpg|.*\\.jpeg|.*\\.webp|.*\\.ico).*)',
  ],
};
