class NationalIdInfo {
  final String birthDate;
  final String birthYear;
  final String birthMonth;
  final String birthDay;
  final String gender;
  final String governorate;

  NationalIdInfo({
    required this.birthDate,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
    required this.gender,
    required this.governorate,
  });
}

class NationalIdUtils {
  static const _governorates = {
    1: 'القاهرة', 2: 'الإسكندرية', 3: 'بورسعيد', 4: 'السويس',
    11: 'دمياط', 12: 'الدقهلية', 13: 'الشرقية', 14: 'القليوبية',
    15: 'كفر الشيخ', 16: 'الغربية', 17: 'المنوفية', 18: 'البحيرة',
    19: 'الإسماعيلية', 21: 'الجيزة', 22: 'بني سويف', 23: 'الفيوم',
    24: 'المنيا', 25: 'أسيوط', 26: 'سوهاج', 27: 'قنا',
    28: 'أسوان', 29: 'الأقصر', 31: 'البحر الأحمر', 32: 'الوادي الجديد',
    33: 'مطروح', 34: 'شمال سيناء', 35: 'جنوب سيناء',
  };

  static NationalIdInfo? parse(String id) {
    if (id.length != 14) return null;
    final centuryDigit = int.tryParse(id[0]);
    if (centuryDigit == null || (centuryDigit != 2 && centuryDigit != 3)) return null;

    final year = (centuryDigit == 2 ? '19' : '20') + id.substring(1, 3);
    final month = id.substring(3, 5);
    final day = id.substring(5, 7);
    final governorateCode = int.tryParse(id.substring(7, 9)) ?? 0;

    final genderDigit = int.tryParse(id[12]);
    if (genderDigit == null) return null;

    final gender = genderDigit % 2 == 0 ? 'أنثى' : 'ذكر';

    return NationalIdInfo(
      birthDate: '$year-$month-$day',
      birthYear: year,
      birthMonth: month,
      birthDay: day,
      gender: gender,
      governorate: _governorates[governorateCode] ?? 'غير معروف',
    );
  }

  static int? calculateAge(String id, {DateTime? referenceDate}) {
    final info = parse(id);
    if (info == null) return null;

    final ref = referenceDate ?? DateTime.now();
    final birth = DateTime(
      int.parse(info.birthYear),
      int.parse(info.birthMonth),
      int.parse(info.birthDay),
    );

    int age = ref.year - birth.year;
    if (ref.month < birth.month || (ref.month == birth.month && ref.day < birth.day)) {
      age--;
    }
    return age;
  }

  static int? extractBirthYear(String id) {
    final info = parse(id);
    if (info == null) return null;
    return int.tryParse(info.birthYear);
  }

  static String? getGenderFromId(String id) {
    return parse(id)?.gender;
  }
}
