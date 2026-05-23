# مسابقة القرآن الكريم - Quran Contest Management System

نظام إدارة مسابقات القرآن الكريم - تطبيق متكامل لإدارة وتنظيم مسابقات حفظ القرآن الكريم.

## نظرة عامة

نظام متكامل يتكون من:
- **تطبيق Flutter** (لوحة تحكم المسؤولين) - يعمل على Windows, Web, Android, iOS
- **موقع Next.js** (الواجهة العامة) - للتسجيل العام والاستعلام عن الحالة
- **قاعدة بيانات Supabase** (PostgreSQL) - مع Row Level Security و Triggers

## المميزات

### لوحة التحكم (Flutter)
- تسجيل المتسابقين مع رفع الصور وشهادات الميلاد
- إدارة المستويات والدرجات
- جدولة الامتحانات
- التقييم والتصنيف
- تصدير التقارير (Excel, PDF)
- طباعة استمارات المتسابقين
- إحصائيات وتحليلات

### الموقع العام (Next.js)
- صفحة تعريفية بالمسابقة
- نموذج تسجيل متعدد الخطوات
- استعلام عن حالة المتسابق
- حماية من البوتات (Cloudflare Turnstile)

## المتطلبات

- Flutter SDK >= 3.0.0
- Node.js >= 18 (للموقع العام)
- حساب Supabase
- حساب Cloudinary

## التثبيت

### تطبيق Flutter
```bash
flutter pub get
cp .env.example .env
# قم بتعديل ملف .env بالبيانات الخاصة بك
flutter run
```

### الموقع العام
```bash
cd next_web
npm install
cp .env.example .env.local
# قم بتعديل ملف .env.local بالبيانات الخاصة بك
npm run dev
```

## هيكل المشروع

```
lib/
├── config/          # التوجيه والمسارات
├── core/            # الثيمات، الثوابت، الأدوات
├── data/            # النماذج والمستودعات
├── services/        # خدمات Supabase, Cloudinary, التصدير, الطباعة
└── ui/              # الشاشات والويدجتات

next_web/
└── src/
    ├── app/         # صفحات Next.js
    ├── components/  # المكونات المشتركة
    └── lib/         # أدوات ومكتبات
```

## قاعدة البيانات

يستخدم النظام Supabase (PostgreSQL) مع:
- جداول: students, admins, competition_levels, app_settings
- Triggers لتوليد أكواد المتسابقين تلقائياً
- Row Level Security (RLS)
- دوال مساعدة للإحصائيات

## الترخيص

جميع الحقوق محفوظة © 2026
