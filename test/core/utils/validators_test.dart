import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/core/utils/validators.dart';

void main() {
  group('validateName', () {
    test('valid name passes', () {
      final result = Validator.validateName('أحمد محمد علي حسن');
      expect(result, isNull);
    });

    test('empty name fails', () {
      final result = Validator.validateName('');
      expect(result, isNotNull);
      expect(result, contains('مطلوب'));
    });

    test('short name fails', () {
      final result = Validator.validateName('أحمد');
      expect(result, isNotNull);
    });

    test('null name fails', () {
      final result = Validator.validateName(null);
      expect(result, isNotNull);
    });
  });

  group('validatePhone', () {
    test('valid 010 phone passes', () {
      expect(Validator.validatePhone('01012345678'), isNull);
    });

    test('valid 011 phone passes', () {
      expect(Validator.validatePhone('01112345678'), isNull);
    });

    test('valid 012 phone passes', () {
      expect(Validator.validatePhone('01212345678'), isNull);
    });

    test('valid 015 phone passes', () {
      expect(Validator.validatePhone('01512345678'), isNull);
    });

    test('invalid prefix fails', () {
      expect(Validator.validatePhone('01312345678'), isNotNull);
    });

    test('too short phone fails', () {
      expect(Validator.validatePhone('0101234567'), isNotNull);
    });

    test('empty phone fails', () {
      expect(Validator.validatePhone(''), isNotNull);
    });
  });

  group('validateStudentPhone', () {
    test('null phone returns null (optional)', () {
      expect(Validator.validateStudentPhone(null), isNull);
    });

    test('empty phone returns null (optional)', () {
      expect(Validator.validateStudentPhone(''), isNull);
    });

    test('invalid optional phone fails', () {
      expect(Validator.validateStudentPhone('01312345678'), isNotNull);
    });
  });

  group('validateNationalId', () {
    test('valid 14-digit ID passes', () {
      expect(Validator.validateNationalId('29801150101234'), isNull);
    });

    test('null ID returns null', () {
      expect(Validator.validateNationalId(null), isNull);
    });

    test('empty ID returns null (optional)', () {
      expect(Validator.validateNationalId(''), isNull);
    });

    test('too short ID fails', () {
      expect(Validator.validateNationalId('123'), isNotNull);
    });

    test('14 non-numeric chars fails', () {
      expect(Validator.validateNationalId('abcdefghijklmn'), isNotNull);
    });

    test('invalid century digit fails', () {
      expect(Validator.validateNationalId('19801150101234'), isNotNull);
    });
  });

  group('validateAge', () {
    test('age 5 passes (minimum)', () {
      expect(Validator.validateAge('5'), isNull);
    });

    test('age 100 passes (maximum)', () {
      expect(Validator.validateAge('100'), isNull);
    });

    test('age below 5 fails', () {
      expect(Validator.validateAge('4'), isNotNull);
    });

    test('age above 100 fails', () {
      expect(Validator.validateAge('101'), isNotNull);
    });

    test('empty age fails', () {
      expect(Validator.validateAge(''), isNotNull);
    });

    test('null age fails', () {
      expect(Validator.validateAge(null), isNotNull);
    });

    test('non-numeric age fails', () {
      expect(Validator.validateAge('abc'), isNotNull);
    });
  });

  group('validateRequired', () {
    test('valid value passes', () {
      expect(Validator.validateRequired('something'), isNull);
    });

    test('null fails', () {
      expect(Validator.validateRequired(null), isNotNull);
    });

    test('empty string fails', () {
      expect(Validator.validateRequired(''), isNotNull);
    });

    test('whitespace only fails', () {
      expect(Validator.validateRequired('   '), isNotNull);
    });
  });

  group('validateLevel', () {
    test('valid level passes', () {
      expect(Validator.validateLevel('المستوى الأول'), isNull);
    });

    test('null fails', () {
      expect(Validator.validateLevel(null), isNotNull);
    });

    test('empty fails', () {
      expect(Validator.validateLevel(''), isNotNull);
    });
  });

  group('validatePassword', () {
    test('valid password passes', () {
      expect(Validator.validatePassword('StrongP@ss1'), isNull);
    });

    test('too short password fails', () {
      expect(Validator.validatePassword('Ab1!'), isNotNull);
    });

    test('no uppercase fails', () {
      expect(Validator.validatePassword('weakpassword1!'), isNotNull);
    });

    test('no digit fails', () {
      expect(Validator.validatePassword('WeakPassword!'), isNotNull);
    });

    test('no special char fails', () {
      expect(Validator.validatePassword('WeakPassword1'), isNotNull);
    });

    test('empty fails', () {
      expect(Validator.validatePassword(''), isNotNull);
    });

    test('null fails', () {
      expect(Validator.validatePassword(null), isNotNull);
    });
  });

  group('isValidImageType', () {
    test('jpg is valid', () {
      expect(Validator.isValidImageType('photo.jpg'), true);
    });

    test('jpeg is valid', () {
      expect(Validator.isValidImageType('photo.jpeg'), true);
    });

    test('png is valid', () {
      expect(Validator.isValidImageType('photo.png'), true);
    });

    test('PNG uppercase is handled', () {
      expect(Validator.isValidImageType('photo.PNG'), true);
    });

    test('gif is invalid', () {
      expect(Validator.isValidImageType('photo.gif'), false);
    });

    test('pdf is invalid', () {
      expect(Validator.isValidImageType('doc.pdf'), false);
    });
  });

  group('isValidImageUrl', () {
    test('valid URL passes', () {
      expect(Validator.isValidImageUrl('https://example.com/photo.jpg'), true);
    });

    test('null fails', () {
      expect(Validator.isValidImageUrl(null), false);
    });

    test('empty fails', () {
      expect(Validator.isValidImageUrl(''), false);
    });

    test('placeholder URL fails', () {
      expect(Validator.isValidImageUrl('https://placehold.co/600x400'), false);
    });
  });
}
