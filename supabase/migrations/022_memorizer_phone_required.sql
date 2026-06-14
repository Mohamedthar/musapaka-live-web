-- ===================================================================
-- Migration 022: رقم هاتف المحفظ إجباري (ممنوع فارغ أو NULL)
-- ===================================================================
-- 1. حذف القيد القديم (كان يسمح بـ NULL وفارغ)
-- 2. تعبئة أي صفوف قديمة لا تحوي رقم هاتف محفظ بصفر (01000000000)
-- 3. إضافة القيد الجديد (إجباري + نمط مصري)
-- ===================================================================

-- الخطوة 1: حذف القيد القديم
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_memorizer_phone_format;

-- الخطوة 2: تعبئة الفراغات القديمة برقم مؤقت (يجب على الأدمن تعديله)
UPDATE students
SET memorizer_phone = '01000000000'
WHERE memorizer_phone IS NULL OR memorizer_phone = '';

-- الخطوة 3: إضافة القيد الجديد (إجباري + نمط مصري)
ALTER TABLE students ADD CONSTRAINT students_memorizer_phone_format CHECK (
    memorizer_phone IS NOT NULL
    AND memorizer_phone <> ''
    AND memorizer_phone ~ '^(010|011|012|015)[0-9]{8}$'
);
