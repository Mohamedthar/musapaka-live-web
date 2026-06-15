import { jsonResponse, optionsResponse, checkRateLimit, getClientIp, validateCsrf } from '@/lib/api-utils';

export { optionsResponse as OPTIONS };

const MAX_FILE_SIZE = 5 * 1024 * 1024;

const ALLOWED_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

const MAGIC_BYTES: Record<string, number[][]> = {
  'image/jpeg': [[0xFF, 0xD8, 0xFF]],
  'image/png': [[0x89, 0x50, 0x4E, 0x47]],
  'image/webp': [[0x52, 0x49, 0x46, 0x46]],
  'image/heic': [[0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63]],
  'image/heif': [[0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63]],
};

async function validateMagicBytes(file: File): Promise<boolean> {
  const buffer = await file.arrayBuffer();
  const bytes = new Uint8Array(buffer);
  const signatures = MAGIC_BYTES[file.type] || MAGIC_BYTES['image/jpeg'];

  return signatures.some((sig) => {
    if (sig.length > bytes.length) return false;
    return sig.every((b, i) => bytes[i] === b);
  });
}

export async function POST(request: Request) {
  const origin = request.headers.get('origin');
  try {
    if (!validateCsrf(request)) {
      return jsonResponse({ error: 'طلب غير مصرح به' }, 403, origin);
    }

    const ip = getClientIp(request);
    if (!checkRateLimit(ip, 10)) {
      return jsonResponse({ error: 'طلبات كثيرة جداً. حاول بعد دقيقة.' }, 429, origin);
    }

    const contentType = request.headers.get('content-type') || '';
    if (!contentType.includes('multipart/form-data')) {
      return jsonResponse({ error: 'نوع المحتوى غير مدعوم' }, 400, origin);
    }

    const formData = await request.formData();
    const file = formData.get('file') as File | null;

    if (!file) {
      return jsonResponse({ error: 'الملف مطلوب' }, 400, origin);
    }

    if (file.size > MAX_FILE_SIZE) {
      return jsonResponse({ error: 'حجم الملف كبير جداً (الحد الأقصى 5 ميجابايت)' }, 400, origin);
    }

    if (!ALLOWED_TYPES.has(file.type)) {
      return jsonResponse({ error: 'نوع الملف غير مدعوم. الأنواع المدعومة: JPEG, PNG, WebP' }, 400, origin);
    }

    const validBytes = await validateMagicBytes(file);
    if (!validBytes) {
      return jsonResponse({ error: 'الملف تالف أو نوعه غير حقيقي' }, 400, origin);
    }

    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const uploadPreset = process.env.CLOUDINARY_UPLOAD_PRESET;

    if (!cloudName || !uploadPreset) {
      return jsonResponse({ error: 'إعدادات السحابة غير صحيحة' }, 500, origin);
    }

    const cloudFormData = new FormData();
    cloudFormData.append('file', file);
    cloudFormData.append('upload_preset', uploadPreset);

    const uploadResponse = await fetch(
      `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
      { method: 'POST', body: cloudFormData, signal: AbortSignal.timeout(25000) }
    );

    const result = await uploadResponse.json();

    if (!uploadResponse.ok) {
      return jsonResponse({ error: result.error?.message || 'فشل رفع الملف' }, 500, origin);
    }

    return jsonResponse({ success: true, url: result.secure_url }, 200, origin);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'حدث خطأ غير متوقع';
    return jsonResponse({ error: message }, 500, origin);
  }
}
