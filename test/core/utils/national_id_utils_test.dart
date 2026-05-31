import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/core/utils/national_id_utils.dart';

void main() {
  group('NationalIdUtils.parse', () {
    test('parses valid male national ID correctly', () {
      final info = NationalIdUtils.parse('29801150101234');
      expect(info, isNotNull);
      expect(info!.birthDate, '1998-01-15');
      expect(info.gender, 'ذكر');
      expect(info.governorate, 'القاهرة');
    });

    test('parses valid female national ID correctly', () {
      final info = NationalIdUtils.parse('29912300201244');
      expect(info, isNotNull);
      expect(info!.birthDate, '1999-12-30');
      expect(info.gender, 'أنثى');
    });

    test('parses 2000s birth year correctly', () {
      final info = NationalIdUtils.parse('30506150101234');
      expect(info, isNotNull);
      expect(info!.birthDate, '2005-06-15');
    });

    test('returns null for invalid length', () {
      expect(NationalIdUtils.parse('12345'), isNull);
      expect(NationalIdUtils.parse('123456789012345'), isNull);
    });

    test('returns null for invalid century digit', () {
      expect(NationalIdUtils.parse('19801150101234'), isNull); // starts with 1
      expect(NationalIdUtils.parse('49801150101234'), isNull); // starts with 4
    });

    test('returns unknown governorate for invalid code', () {
      final info = NationalIdUtils.parse('29801150001234');
      expect(info, isNotNull);
      expect(info!.governorate, 'غير معروف');
    });
  });

  group('NationalIdUtils.calculateAge', () {
    test('calculates age correctly', () {
      final refDate = DateTime(2026, 5, 27);
      final age = NationalIdUtils.calculateAge('29906010101234', referenceDate: refDate);
      expect(age, 26); // Born 1999-06-01, ref 2026-05-27 → 26 (birthday not yet)
    });

    test('calculates age when birthday has passed', () {
      final refDate = DateTime(2026, 8, 1);
      final age = NationalIdUtils.calculateAge('29906010101234', referenceDate: refDate);
      expect(age, 27); // Born 1999-06-01, ref 2026-08-01 → 27
    });

    test('returns null for invalid ID', () {
      expect(NationalIdUtils.calculateAge('12345'), isNull);
    });
  });

  group('NationalIdUtils.getGenderFromId', () {
    test('returns male for odd 13th digit', () {
      expect(NationalIdUtils.getGenderFromId('29801150101231'), 'ذكر');
    });

    test('returns female for even 13th digit', () {
      expect(NationalIdUtils.getGenderFromId('29801150101244'), 'أنثى');
    });
  });
}
