export const PHONE_REGEX = /^(010|011|012|015)\d{8}$/;
export const NATIONAL_ID_REGEX = /^\d{14}$/;

export function validatePhone(phone: string): boolean {
  return PHONE_REGEX.test(phone.trim());
}

export function validateNationalId(nationalId: string): boolean {
  return NATIONAL_ID_REGEX.test(nationalId.trim());
}
