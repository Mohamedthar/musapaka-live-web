-- =============================================
-- Migration: Security Hardening
-- إغلاق ثغرات أمنية في دوال الاستعلام العامة
-- =============================================
BEGIN;

-- 1. تعديل public_lookup_student ليتطلب رقم الهاتف مع الرقم القومي (توثيق ثنائي)
DROP FUNCTION IF EXISTS public_lookup_student(TEXT);

CREATE OR REPLACE FUNCTION public_lookup_student(p_national_id TEXT, p_phone TEXT)
RETURNS TABLE (
    id INTEGER,
    student_code TEXT,
    name TEXT,
    phone TEXT,
    national_id TEXT,
    age INTEGER,
    gender TEXT,
    level TEXT,
    level_id INTEGER,
    level_content TEXT,
    selected_rewaya TEXT,
    branch_name TEXT,
    memorization_amount INTEGER,
    memorizer_name TEXT,
    memorizer_phone TEXT,
    memorizer_address TEXT,
    location TEXT,
    birth_date DATE,
    profile_image_url TEXT,
    birth_certificate_url TEXT,
    exam_date DATE,
    exam_hour INTEGER,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id, s.student_code, s.name, s.phone, s.national_id,
        s.age, s.gender, s.level, s.level_id,
        cl.content AS level_content,
        s.selected_rewaya, s.branch_name, s.memorization_amount,
        s.memorizer_name, s.memorizer_phone, s.memorizer_address,
        s.location, s.birth_date,
        s.profile_image_url, s.birth_certificate_url,
        s.exam_date, s.exam_hour, s.created_at
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id
      AND s.phone = p_phone
    LIMIT 1;
END;
$$;

-- 2. إلغاء صلاحية anon من دوال الاستعلام الحساسة (تتم عبر API فقط باستخدام service_role)
--    صلاحية authenticated للاستخدام الداخلي فقط
REVOKE ALL ON FUNCTION public_lookup_student(TEXT, TEXT) FROM anon;
REVOKE ALL ON FUNCTION public_lookup_result(TEXT) FROM anon;
REVOKE ALL ON FUNCTION public_lookup_ceremony(TEXT) FROM anon;
REVOKE ALL ON FUNCTION public_get_registration_status() FROM anon;
REVOKE ALL ON FUNCTION public_get_home_stats() FROM anon;

GRANT EXECUTE ON FUNCTION public_lookup_student(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public_lookup_result(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public_lookup_ceremony(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public_get_registration_status() TO authenticated;
GRANT EXECUTE ON FUNCTION public_get_home_stats() TO authenticated;

COMMIT;
