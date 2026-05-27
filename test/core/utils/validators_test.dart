import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/core/utils/validators.dart';

void main() {
  group('Validator.validateRequired', () {
    test('returns error for null', () {
      expect(Validator.validateRequired(null), isNotNull);
    });
    test('returns error for empty', () {
      expect(Validator.validateRequired(''), isNotNull);
    });
    test('returns null for valid value', () {
      expect(Validator.validateRequired('test'), isNull);
    });
  });

  group('Validator.validateName', () {
    test('returns error for short name', () {
      expect(Validator.validateName('اسم قصير'), isNotNull);
    });
    test('returns null for 10+ character name', () {
      expect(Validator.validateName('أحمد محمد علي حسن'), isNull);
    });
  });

  group('Validator.validatePhone', () {
    test('rejects invalid prefix', () {
      expect(Validator.validatePhone('02012345678'), isNotNull);
    });
    test('rejects short number', () {
      expect(Validator.validatePhone('010123'), isNotNull);
    });
    test('accepts valid Egyptian number', () {
      expect(Validator.validatePhone('01012345678'), isNull);
      expect(Validator.validatePhone('01112345678'), isNull);
      expect(Validator.validatePhone('01212345678'), isNull);
      expect(Validator.validatePhone('01512345678'), isNull);
    });
  });

  group('Validator.validateNationalId', () {
    test('returns null for empty (optional field)', () {
      expect(Validator.validateNationalId(''), isNull);
      expect(Validator.validateNationalId(null), isNull);
    });
    test('rejects non-14-digit', () {
      expect(Validator.validateNationalId('12345'), isNotNull);
      expect(Validator.validateNationalId('12345678901234'), isNull);
    });
    test('rejects invalid century', () {
      expect(Validator.validateNationalId('19801150101234'), isNotNull);
    });
    test('accepts valid ID', () {
      expect(Validator.validateNationalId('29801150101234'), isNull);
    });
  });

  group('Validator.validatePassword', () {
    test('rejects short password', () {
      expect(Validator.validatePassword('Ab1!'), isNotNull);
    });
    test('rejects missing uppercase', () {
      expect(Validator.validatePassword('abcdef1!'), isNotNull);
    });
    test('rejects missing lowercase', () {
      expect(Validator.validatePassword('ABCDEF1!'), isNotNull);
    });
    test('rejects missing number', () {
      expect(Validator.validatePassword('Abcdef!@'), isNotNull);
    });
    test('rejects missing symbol', () {
      expect(Validator.validatePassword('Abc12345'), isNotNull);
    });
    test('accepts valid password', () {
      expect(Validator.validatePassword('Abc12345!'), isNull);
    });
  });

  group('Validator.isValidImageUrl', () {
    test('rejects null and empty', () {
      expect(Validator.isValidImageUrl(null), false);
      expect(Validator.isValidImageUrl(''), false);
    });
    test('rejects placeholder', () {
      expect(Validator.isValidImageUrl('https://placehold.co/600x400'), false);
    });
    test('accepts valid URL', () {
      expect(Validator.isValidImageUrl('https://res.cloudinary.com/demo/image.jpg'), true);
    });
  });
}
