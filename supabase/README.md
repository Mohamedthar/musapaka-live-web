# قاعدة البيانات — Database Setup

## هيكل الملفات

```
supabase/
├── schema.sql              # المخطط الكامل (جداول، قيود، فهارس، RLS، محفزات، دوال)
├── migrations/             # ترحيلات تزايدية (لتطبيق تغييرات على قاعدة بيانات موجودة)
│   ├── 001_add_prize_columns.sql
│   ├── 002_add_waitlist_ceremony.sql
│   └── 003_add_level_id_fk.sql
└── README.md
```

## طريقة التشغيل

### إنشاء قاعدة بيانات جديدة
شغّل `schema.sql` مرة واحدة في SQL Editor.
الملف آمن للتشغيل المتكرر (`IF NOT EXISTS` / `CREATE OR REPLACE`).

### التحديث من إصدار أقدم
شغّل ملفات `migrations/` بالترتيب (كلها تستخدم `ADD COLUMN IF NOT EXISTS`).

## محتويات schema.sql

| القسم | المحتوى |
|-------|---------|
| 1 | الجداول + البيانات الابتدائية |
| 2 | القيود (CHECK, UNIQUE, FK, NOT NULL) |
| 3 | الفهارس (عادية, مركبة, جزئية, فريدة) |
| 4 | أمان الصفوف (RLS policies) |
| 5 | المحفزات (8 triggers) |
| 6 | الدوال الداخلية (is_admin, statistics, status) |
| 7 | دوال الـ API العامة (للاستعلامات من Next.js) |
| 8 | دوال الحفل (generate_all_ceremony_codes) |
