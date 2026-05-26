# مسابقة القرآن الكريم - Quran Contest Management System

نظام متكامل لإدارة مسابقات القرآن الكريم - Flutter + Next.js + Supabase.  
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Next.js](https://img.shields.io/badge/Next.js-16-black?logo=next.js)](https://nextjs.org)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)](https://supabase.com)

---

## المكونات

| المكون | التقنية | الوصف |
|--------|---------|-------|
| تطبيق الإدارة | Flutter (Windows/Web/Android/iOS) | لوحة تحكم كاملة للمسؤولين |
| الموقع العام | Next.js 16 + React 19 | تسجيل المتسابقين والاستعلام |
| قاعدة البيانات | Supabase PostgreSQL | RLS + Triggers + دوال مساعدة |
| الصور | Cloudinary | رفع وتخزين الصور |

---

## المميزات

### تطبيق الإدارة (Flutter)
- تسجيل وإدارة المتسابقين مع الصور (ملف شخصي + شهادة ميلاد)
- إدارة مستويات المنافسة (الدرجات، الفروع، الجوائز)
- جدولة تلقائية للامتحانات (FIFO)
- تقييم وتحكيم (تلاوة، تجويد، صوت، معاني)
- تصدير Excel + PDF مع رسوم بيانية
- طباعة استمارات وبطاقات المتسابقين
- إحصائيات ورسم بياني (fl_chart)
- نظام صلاحيات (مسؤول واحد أو أكثر)

### الموقع العام (Next.js)
- الصفحة الرئيسية التعريفية
- نموذج تسجيل متعدد الخطوات (5 خطوات)
- استعلام عن النتيجة برقم الهاتف أو الرقم القومي
- استعلام عن دعوة الحفل (مصادقة ثنائية)
- حماية Turnstile من البوتات
- تصميم RTL بالكامل مع خط Cairo

---

## هيكل المشروع

```
musapaka/
├── lib/                          # Flutter app source
│   ├── main.dart                 # نقطة البداية
│   ├── config/routes.dart        # المسارات
│   ├── core/                     # الثوابت، السمة، الأدوات
│   ├── data/                     # النماذج والمستودعات
│   ├── services/                 # Supabase, Cloudinary, تصدير, طباعة
│   └── ui/                       # الشاشات
│       ├── auth/                 # المصادقة
│       ├── dashboard/            # لوحة التحكم
│       ├── registration/         # تسجيل الطلاب
│       ├── exams/                # التحكيم
│       ├── levels/               # المستويات
│       ├── statistics/           # الإحصائيات
│       └── settings/             # الإعدادات
├── next_web/                     # Next.js public site
│   └── src/
│       ├── app/                  # الصفحات و API routes
│       ├── components/           # Header, Footer, FaqSection
│       └── lib/                  # Supabase clients & types
└── supabase/
    ├── schema.sql                # مخطط قاعدة البيانات الكامل
    └── migrations/               # الترحيلات
```

---

## التثبيت والتشغيل

### المتطلبات
- Flutter SDK >= 3.0.0
- Node.js >= 18
- حساب Supabase
- حساب Cloudinary

### تطبيق Flutter
```bash
cp .env.example .env
# عدّل .env بمفاتيح Supabase و Cloudinary
flutter pub get
flutter run
```

### الموقع العام
```bash
cd next_web
npm install
# أضف متغيرات البيئة:
# NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY
# SUPABASE_SERVICE_ROLE_KEY, NEXT_PUBLIC_TURNSTILE_SITE_KEY
# TURNSTILE_SECRET_KEY, NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME
# NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET
npm run dev
```

### قاعدة البيانات
```bash
# 1. افتح Supabase SQL Editor
# 2. الصق محتوى supabase/schema.sql
# 3. ثم الصق supabase/migrations/ceremony_attendance.sql
# 4. ثم الصق supabase/migrations/fixes_comprehensive.sql
```

---

## متغيرات البيئة

### `.env` (Flutter)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_UPLOAD_PRESET=your-upload-preset
```

### `.env.local` (Next.js)
```env
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_TURNSTILE_SITE_KEY=
TURNSTILE_SECRET_KEY=
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=
```

---

## قاعدة البيانات

| الجدول | الوصف |
|--------|-------|
| `students` | بيانات المتسابقين |
| `competition_levels` | مستويات المسابقة |
| `admins` | المسؤولين |
| `app_settings` | إعدادات التطبيق |

**Triggers رئيسية:**
- `generate_student_code` - توليد كود تلقائي (A1001)
- `assign_exam_slot` - جدولة تلقائية
- `check_level_capacity` - التحقق من سعة المستوى
- `regenerate_student_code_on_level_change` - إعادة توليد الكود

**RLS:** القراءة العامة للمستويات والإعدادات، الكتابة للمسؤولين فقط.

---

## سير العمل

1. المسؤول يضبط الإعدادات (مواعيد التسجيل، الامتحانات، المستويات)
2. المتسابق يسجل عبر الموقع العام (5 خطوات)
3. النظام يعين تلقائياً: كود المتسابق + موعد الامتحان
4. المسؤول يقيم المتسابق عبر تطبيق الإدارة
5. النتائج متاحة للاستعلام عبر الموقع العام
6. المسؤول يولد أكواد الحفل ويعلن النتائج النهائية
