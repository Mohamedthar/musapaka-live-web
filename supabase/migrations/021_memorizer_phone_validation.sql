-- ===================================================================
-- Migration 021: تفعيل تحقق رقم هاتف المحفظ (مصري: 010/011/012/015)
-- ===================================================================
-- 1. تنظيف البيانات القديمة غير المطابقة
-- 2. إضافة قيد CHECK على عمود memorizer_phone
-- ===================================================================

-- الخطوة 1: مسح أرقام الهاتف غير المصرية (جعلها NULL)
UPDATE students
SET memorizer_phone = NULL
WHERE memorizer_phone IS NOT NULL
  AND memorizer_phone <> ''
  AND memorizer_phone !~ '^(010|011|012|015)[0-9]{8}$';

-- الخطوة 2: إضافة قيد التحقق
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_memorizer_phone_format') THEN
        ALTER TABLE students ADD CONSTRAINT students_memorizer_phone_format CHECK (
            memorizer_phone IS NULL
            OR memorizer_phone = ''
            OR memorizer_phone ~ '^(010|011|012|015)[0-9]{8}$'
        );
    END IF;
END $$;
