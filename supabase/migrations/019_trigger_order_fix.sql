-- =================================================================================================
-- Migration 019 — إصلاح ترتيب المحفزات + أمان الدوال + تنظيف الفهارس
-- =================================================================================================
-- تاريخ: 2026-06-12
-- 1. إصلاح ترتيب trg_check_level_capacity ليعمل بعد trg_sync_level_id
-- 2. إضافة REVOKE EXECUTE FROM PUBLIC للدوال الحساسة
-- 3. إضافة GRANT EXECUTE ON is_admin() للـ anon, authenticated
-- 4. حذف الفهرس المكرر idx_students_nid_student_code
-- 5. إضافة SET search_path للدوال الناقصة
-- =================================================================================================

-- -------------------------------------------------------------------
-- 1. إصلاح ترتيب المحفزات — فحص السعة يجب أن ينفذ بعد مزامنة level_id
-- -------------------------------------------------------------------
-- المحفزات تنفذ بالترتيب الأبجدي: trg_check (c) كان قبل trg_sync (s) خطأ!
-- الحل: إعادة تسميته إلى trg_z_check ليأتي بعد trg_sync
DROP TRIGGER IF EXISTS trg_check_level_capacity ON students;
DROP TRIGGER IF EXISTS trg_z_check_level_capacity ON students;
CREATE TRIGGER trg_z_check_level_capacity
    BEFORE INSERT ON students FOR EACH ROW
    EXECUTE FUNCTION check_level_capacity();

-- -------------------------------------------------------------------
-- 2. أمان الدوال — منع PUBLIC/anon من تنفيذ الدوال الحساسة
-- -------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION get_student_status(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_student_status(TEXT, TEXT) TO authenticated;

REVOKE EXECUTE ON FUNCTION retrieve_student_code(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION retrieve_student_code(TEXT, TEXT) TO authenticated;

REVOKE EXECUTE ON FUNCTION query_ceremony_attendance(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION query_ceremony_attendance(TEXT, TEXT) TO authenticated;

REVOKE EXECUTE ON FUNCTION generate_all_ceremony_codes() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION generate_all_ceremony_codes() TO authenticated;

REVOKE EXECUTE ON FUNCTION get_student_stats() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_student_stats() TO authenticated;

REVOKE EXECUTE ON FUNCTION get_student_stats(TEXT, TEXT, DATE, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_student_stats(TEXT, TEXT, DATE, DATE) TO authenticated;

-- is_admin() يجب أن يكون متاحاً للكل لأنه يستخدم في RLS policies
GRANT EXECUTE ON FUNCTION is_admin() TO anon, authenticated;

-- -------------------------------------------------------------------
-- 3. إضافة SET search_path للدوال الناقصة
-- -------------------------------------------------------------------
ALTER FUNCTION get_student_stats() SET search_path = public;
ALTER FUNCTION get_student_stats(TEXT, TEXT, DATE, DATE) SET search_path = public;

-- -------------------------------------------------------------------
-- 4. حذف الفهرس المكرر (نفس الأعمدة بنفس الترتيب)
-- -------------------------------------------------------------------
DROP INDEX IF EXISTS idx_students_nid_student_code;

-- -------------------------------------------------------------------
-- 5. إضافة قيد CHECK على gender
-- -------------------------------------------------------------------
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_gender_check;
ALTER TABLE students ADD CONSTRAINT students_gender_check
    CHECK (gender IS NULL OR gender IN ('ذكر', 'أنثى'));
