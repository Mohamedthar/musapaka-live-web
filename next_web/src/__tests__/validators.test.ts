import { describe, it, expect } from 'vitest';
import { validatePhone, validateNationalId } from '@/lib/validators';

describe('validators', () => {
  describe('validatePhone', () => {
    it('accepts valid 010 number', () => {
      expect(validatePhone('01012345678')).toBe(true);
    });

    it('accepts valid 011 number', () => {
      expect(validatePhone('01112345678')).toBe(true);
    });

    it('accepts valid 012 number', () => {
      expect(validatePhone('01212345678')).toBe(true);
    });

    it('accepts valid 015 number', () => {
      expect(validatePhone('01512345678')).toBe(true);
    });

    it('rejects invalid prefix', () => {
      expect(validatePhone('02012345678')).toBe(false);
      expect(validatePhone('01612345678')).toBe(false);
    });

    it('rejects too short number', () => {
      expect(validatePhone('01012345')).toBe(false);
    });

    it('rejects too long number', () => {
      expect(validatePhone('010123456789')).toBe(false);
    });

    it('rejects non-numeric', () => {
      expect(validatePhone('0101abcdefg')).toBe(false);
    });

    it('trims whitespace', () => {
      expect(validatePhone(' 01012345678 ')).toBe(true);
    });
  });

  describe('validateNationalId', () => {
    it('accepts 14-digit ID', () => {
      expect(validateNationalId('29801150101234')).toBe(true);
    });

    it('rejects non-14-digit', () => {
      expect(validateNationalId('12345')).toBe(false);
      expect(validateNationalId('123456789012345')).toBe(false);
    });

    it('rejects non-numeric', () => {
      expect(validateNationalId('abcdefghijklmn')).toBe(false);
    });
  });
});
