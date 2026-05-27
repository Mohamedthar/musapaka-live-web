import { describe, it, expect } from 'vitest';
import { parseNationalId, calculateAgeFromNationalId } from '@/lib/national-id';

describe('national-id', () => {
  describe('parseNationalId', () => {
    it('parses valid male national ID', () => {
      const result = parseNationalId('29801150101234');
      expect(result).not.toBeNull();
      expect(result!.birthDate).toBe('1998-01-15');
      expect(result!.gender).toBe('ذكر');
      expect(result!.governorate).toBe('القاهرة');
    });

    it('parses female national ID', () => {
      const result = parseNationalId('29912300201244');
      expect(result).not.toBeNull();
      expect(result!.birthDate).toBe('1999-12-30');
      expect(result!.gender).toBe('أنثى');
    });

    it('parses 2005 birth year', () => {
      const result = parseNationalId('30506150101234');
      expect(result).not.toBeNull();
      expect(result!.birthDate).toBe('2005-06-15');
    });

    it('returns null for invalid length', () => {
      expect(parseNationalId('12345')).toBeNull();
      expect(parseNationalId('123456789012345')).toBeNull();
    });

    it('returns null for empty string', () => {
      expect(parseNationalId('')).toBeNull();
    });

    it('returns unknown for invalid governorate', () => {
      const result = parseNationalId('29801150001234');
      expect(result).not.toBeNull();
      expect(result!.governorate).toBe('غير معروف');
    });
  });

  describe('calculateAgeFromNationalId', () => {
    it('calculates age correctly', () => {
      const refDate = new Date(2026, 4, 27); // May 27, 2026
      const age = calculateAgeFromNationalId('29906010101234', refDate);
      expect(age).toBe(26); // Born 1999-06-01, ref 2026-05-27 → 26
    });

    it('accounts for birthday not yet passed', () => {
      const refDate = new Date(2026, 7, 1); // Aug 1, 2026
      const age = calculateAgeFromNationalId('29906010101234', refDate);
      expect(age).toBe(27); // Born 1999-06-01, ref 2026-08-01 → 27
    });

    it('returns null for invalid ID', () => {
      expect(calculateAgeFromNationalId('12345')).toBeNull();
    });
  });
});
