# الترحيلات التزايدية — Incremental Migrations

يجب تشغيل الملفات بالترتيب التالي.

## ترتيب التشغيل

| # | الملف | الوصف |
|---|-------|-------|
| 1 | `001_add_prize_columns.sql` | إضافة `first_prize`, `second_prize`, `third_prize`, `prizes` إلى `competition_levels` |
| 2 | `002_add_waitlist_ceremony.sql` | إضافة `is_waitlisted`, `ceremony_code` للطلاب و `is_ceremony_query_open` للإعدادات |
| 3 | `003_add_level_id_fk.sql` | إضافة `level_id` FK مع trigger للمزامنة، فحص السعة، وتوليد أكواد الحفل |
| 4 | `004_remove_waitlist_dates.sql` | إزالة منطق قائمة الانتظار، تحديث `public_get_registration_status` |
| 5 | `005_fix_ceremony_codes_chr.sql` | إعادة بناء `generate_all_ceremony_codes` بصيغة `M-01-S-050` |
| 6 | `006_add_missing_settings_columns.sql` | إضافة `result_query_open_date`, `ceremony_query_open_date` إلى `app_settings` |
| 7 | `010_add_max_score_to_competition_levels.sql` | إضافة `max_score` (INTEGER DEFAULT 100) إلى `competition_levels` |
| 8 | `011_fix_all_missing_columns.sql` | إضافة `selected_rewaya` إلى `students`، و `max_score`، وتواريخ الاستعلام. إعادة إنشاء دوال RPC |
| 9 | `012_fix_students_score_columns_type.sql` | تغيير أنواع أعمدة الدرجات في `students` من NUMERIC(5,2) → DOUBLE PRECISION |
| 10 | `014_fix_ceremony_eligibility.sql` | **إضافة حساب النسبة المئوية والأهلية (`is_eligible`)** في `public_lookup_ceremony`. المتسابق مؤهل ≥ 95% |
| 11 | `015_remove_age_constraint.sql` | إزالة قيد العمر `students_age_check` |
| 12 | `016_add_passing_percentage.sql` | إضافة `passing_percentage` لكل مستوى — نسبة نجاح ديناميكية بدل 95% الثابتة |

## ملاحظات

- جميع الملفات آمنة للتشغيل المتكرر (`DROP IF EXISTS` + `CREATE OR REPLACE`)
- للإنشاء من البداية: استخدم `schema.sql` (في المجلد الأعلى) ثم شغّل كل migrations بالترتيب
- **آخر تحديث (014):** أصلحنا مشكلة أن `public_lookup_ceremony` كانت لا تحسب النسبة المئوية، مما جعل جميع المستخدمين يرون رسالة "نسبتك أقل من 95%" حتى لو كانت نسبتهم 100%
- **ملفات تم حذفها (لأنها لا تحتوي إلا على إعادة كتابة دوال RPC وتم استبدالها لاحقاً):**
  - ~~`007_fix_score_column_types.sql`~~ ← استُبدلت بـ 011, 013, 014
  - ~~`008_fix_level_code_type.sql`~~ ← استُبدلت بـ 011, 013, 014
  - ~~`009_remove_phone_from_public_rpcs.sql`~~ ← استُبدلت بـ 011, 013, 014
  - ~~`013_fix_ceremony_id_ambiguity.sql`~~ ← استُبدلت بـ 014

## الترقيم

تم الاحتفاظ بأرقام الملفات الأصلية لتجنب كسر تتبع Supabase. الترقيم الحالي: 001–006, 010–012, 014. أي ملف جديد يبدأ من **015**.

## ملخص المشاكل التي تم حلها

| المشكلة | الترحيل | الوصف |
|---------|---------|-------|
| عدم وجود `is_eligible` | `014` | `public_lookup_ceremony` الآن تحسب `total_score / max_score * 100` وتعيد `is_eligible` |
| خطأ 95% لجميع المستخدمين | `014` | كان `is_eligible` دائماً `undefined` (falsy) في الواجهة. الآن يرجع boolean حقيقي |
| غموض `id` في ceremony | `013`→`014` | إصلاح `WHERE id = 1` → `WHERE app_settings.id = 1` (مدمج في 014) |
| تكرار إضافة الأعمدة | `010`+`011` | `max_score` أضيف مرتين (مع `IF NOT EXISTS`) |
