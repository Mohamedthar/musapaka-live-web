import 'national_id_utils.dart';

class Validator {
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 10) {
      return 'الاسم يجب أن يتكون من 4 أسماء على الأقل (10 أحرف)';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'العمر مطلوب';
    }
    final int? age = int.tryParse(value);
    if (age == null) {
      return 'العمر يجب ان يكون رقما';
    }
    if (age < 1 || age > 100) {
      return 'العمر يجب ان يكون بين 1 و 100';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final phoneRegex = RegExp(r'^(010|011|012|015)[0-9]{8}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'رقم الهاتف المصري غير صحيح (مثال: 01012345678)';
    }
    return null;
  }

  static String? validateStudentPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^(010|011|012|015)[0-9]{8}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  static String? validateNationalId(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^\d{14}$').hasMatch(value.trim())) {
      return 'الرقم القومي يجب أن يكون 14 رقماً';
    }
    // التحقق من صحة القرن
    final firstDigit = int.tryParse(value.substring(0, 1));
    if (firstDigit != 2 && firstDigit != 3) {
      return 'الرقم القومي غير صحيح';
    }
    return null;
  }

  static int? calculateAgeFromNationalId(String id) {
    return NationalIdUtils.calculateAge(id);
  }

  static String? getGenderFromNationalId(String id) {
    return NationalIdUtils.getGenderFromId(id);
  }

  static String? validateLevel(String? value) {
    if (value == null || value.isEmpty) {
      return 'المستوى مطلوب';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على رمز خاص واحد على الأقل';
    }
    return null;
  }

  static bool isValidImageType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return extension == 'jpg' || extension == 'jpeg' || extension == 'png' || extension == 'webp' || extension == 'heic' || extension == 'heif';
  }

  static bool isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    if (url.contains('placehold')) return false;
    return true;
  }
}
