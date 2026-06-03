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
      { method: 'POST', body: cloudFormData }
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
