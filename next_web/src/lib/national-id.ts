export interface NationalIdInfo {
  birthDate: string;
  gender: string;
  governorate: string;
}

export function parseNationalId(id: string): NationalIdInfo | null {
  if (!id || id.length !== 14) return null;

  const centuryDigit = parseInt(id[0], 10);
  const year = (centuryDigit === 2 ? '19' : '20') + id.substring(1, 3);
  const month = id.substring(3, 5);
  const day = id.substring(5, 7);
  const governorateCode = parseInt(id.substring(7, 9), 10);
  const genderDigit = parseInt(id[12], 10);

  const gender = genderDigit % 2 === 0 ? 'أنثى' : 'ذكر';

  const governorates: Record<number, string> = {
    1: 'القاهرة', 2: 'الإسكندرية', 3: 'بورسعيد', 4: 'السويس',
    11: 'دمياط', 12: 'الدقهلية', 13: 'الشرقية', 14: 'القليوبية',
    15: 'كفر الشيخ', 16: 'الغربية', 17: 'المنوفية', 18: 'البحيرة',
    19: 'الإسماعيلية', 21: 'الجيزة', 22: 'بني سويف', 23: 'الفيوم',
    24: 'المنيا', 25: 'أسيوط', 26: 'سوهاج', 27: 'قنا',
    28: 'أسوان', 29: 'الأقصر', 31: 'البحر الأحمر', 32: 'الوادي الجديد',
    33: 'مطروح', 34: 'شمال سيناء', 35: 'جنوب سيناء',
  };

  return {
    birthDate: `${year}-${month}-${day}`,
    gender,
    governorate: governorates[governorateCode] || 'غير معروف',
  };
}

export function calculateAgeFromNationalId(id: string, referenceDate?: Date): number | null {
  const info = parseNationalId(id);
  if (!info) return null;

  const [year, month, day] = info.birthDate.split('-').map(Number);
  const birth = new Date(year, month - 1, day);
  const ref = referenceDate ?? new Date();

  let age = ref.getFullYear() - birth.getFullYear();
  const monthDiff = ref.getMonth() - birth.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && ref.getDate() < birth.getDate())) {
    age--;
  }
  return age;
}
