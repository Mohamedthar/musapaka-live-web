import { describe, it, expect, beforeEach } from 'vitest';
import { checkRateLimit, getClientIp, validateCsrf } from '@/lib/api-utils';

describe('api-utils', () => {
  describe('getClientIp', () => {
    it('returns IP from x-forwarded-for header', () => {
      const req = new Request('https://example.com', {
        headers: { 'x-forwarded-for': '192.168.1.1, 10.0.0.1' },
      });
      expect(getClientIp(req)).toBe('192.168.1.1');
    });

    it('returns unknown when no headers', () => {
      const req = new Request('https://example.com');
      expect(getClientIp(req)).toBe('unknown');
    });

    it('trims whitespace from IP', () => {
      const req = new Request('https://example.com', {
        headers: { 'x-forwarded-for': '  10.0.0.5  ' },
      });
      expect(getClientIp(req)).toBe('10.0.0.5');
    });
  });

  describe('checkRateLimit', () => {
    beforeEach(() => {
      // Clear rate limit state between tests
    });

    it('allows first request', () => {
      expect(checkRateLimit('1.1.1.1', 5)).toBe(true);
    });

    it('allows requests within limit', () => {
      const ip = '2.2.2.2';
      expect(checkRateLimit(ip, 5)).toBe(true);
      expect(checkRateLimit(ip, 5)).toBe(true);
      expect(checkRateLimit(ip, 5)).toBe(true);
      expect(checkRateLimit(ip, 5)).toBe(true);
      expect(checkRateLimit(ip, 5)).toBe(true);
    });

    it('blocks requests exceeding limit', () => {
      const ip = '3.3.3.3';
      for (let i = 0; i < 3; i++) {
        expect(checkRateLimit(ip, 3)).toBe(true);
      }
      expect(checkRateLimit(ip, 3)).toBe(false);
    });

    it('treats different IPs separately', () => {
      expect(checkRateLimit('4.4.4.4', 2)).toBe(true);
      expect(checkRateLimit('5.5.5.5', 2)).toBe(true);
      expect(checkRateLimit('4.4.4.4', 2)).toBe(true);
    });
  });

  describe('validateCsrf', () => {
    it('returns false for request without origin or referer', () => {
      const req = new Request('https://example.com');
      expect(validateCsrf(req)).toBe(false);
    });

    it('validates allowed origin', () => {
      const originalEnv = process.env.NEXT_PUBLIC_SITE_URL;
      process.env.NEXT_PUBLIC_SITE_URL = 'https://mysite.com';

      const req = new Request('https://example.com/api', {
        headers: { origin: 'https://mysite.com' },
      });
      expect(validateCsrf(req)).toBe(true);

      process.env.NEXT_PUBLIC_SITE_URL = originalEnv;
    });

    it('rejects unknown origin', () => {
      const req = new Request('https://example.com/api', {
        headers: { origin: 'https://evil.com' },
      });
      expect(validateCsrf(req)).toBe(false);
    });
  });
});
