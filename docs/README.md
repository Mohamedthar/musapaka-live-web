# مسابقة أهل القرآن الكبرى — توثيق المشروع

## هيكل المشروع

```
musapaka/
├── next_web/          # الموقع العام (Next.js 16 + React 19)
├── lib/               # تطبيق الإدارة (Flutter + Dart)
├── supabase/          # قاعدة البيانات (PostgreSQL + RLS + Triggers)
├── assets/            # الصور والخطوط
└── .github/           # CI/CD workflows
```

## تشغيل المشروع

### 1. قاعدة البيانات (Supabase)
```bash
# شغّل الملف الرئيسي في Supabase SQL Editor
supabase/schema.sql

# ثم الترحيلات بالترتيب
supabase/migrations/001_*.sql → 015_*.sql
```

### 2. الموقع العام (Next.js)
```bash
cd next_web
npm install
# أنشئ ملف .env.local
cp .env.example .env.local
npm run dev      # تطوير
npm run build    # بناء للإنتاج
```

### 3. تطبيق الإدارة (Flutter)
```bash
# تأكد من وجود .env في المجلد الرئيسي
flutter pub get
flutter run -d windows
```

---

## الروابط الرئيسية

| الرابط | الوصف |
|--------|-------|
| `/` | الصفحة الرئيسية |
| `/register` | صفحة التسجيل |
| `/status` | الاستعلام (استمارة / نتيجة / حفل) |
| `/levels` | مستويات المسابقة وجوائزها |

## API Endpoints

| المسار | النوع | الوصف |
|--------|-------|-------|
| `/api/settings` | GET | إعدادات التطبيق + حالة التسجيل |
| `/api/levels` | GET | المستويات النشطة |
| `/api/register` | POST | تسجيل متسابق جديد |
| `/api/upload` | POST | رفع الصور (Cloudinary) |
| `/api/inquiry` | POST | الاستعلام عن استمارة |
| `/api/result` | GET/POST | الاستعلام عن النتيجة |
| `/api/ceremony` | GET/POST | الاستعلام عن الحفل |
| `/api/faq` | GET | الأسئلة الشائعة |
| `/api/check-duplicate` | POST | فحص تكرار الاسم/الرقم القومي |

## متغيرات البيئة

### `next_web/.env.local`
```
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
TURNSTILE_SECRET_KEY=...
NEXT_PUBLIC_SITE_URL=https://musapaka.com
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_UPLOAD_PRESET=...
```

### `.env` (Flutter)
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_UPLOAD_PRESET=...
```
