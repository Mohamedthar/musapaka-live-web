-- =================================================================================================
-- تشغيل هذا الملف في Supabase SQL Editor لدعم منطق إغلاق التسجيل في حالتين:
--   1. زر الغلق العادي في الإعدادات (is_registration_open = false)
--   2. لا توجد مواعيد اختبار مضافة (exam_schedule = [])
-- =================================================================================================

-- 1. تأكد من وجود صف الإعدادات
INSERT INTO app_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- 2. دالة حالة التسجيل (RPC)
DROP FUNCTION IF EXISTS public_get_registration_status();
CREATE OR REPLACE FUNCTION public_get_registration_status()
RETURNS TABLE (
    is_registration_open    BOOLEAN,
    has_available_slots     BOOLEAN,
    is_result_query_open    BOOLEAN,
    is_ceremony_query_open  BOOLEAN,
    result_query_open_date  TIMESTAMPTZ,
    ceremony_query_open_date TIMESTAMPTZ,
    competition_title       TEXT,
    total_slots             BIGINT,
    filled_slots            BIGINT,
    total_students          BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_total_slots    BIGINT := 0;
    v_filled_slots   BIGINT := 0;
    v_total_students BIGINT := 0;
BEGIN
    SELECT COALESCE(SUM(
        ((slot->>'end_hour')::INT - (slot->>'start_hour')::INT) *
        COALESCE((slot->>'students_per_hour')::INT, 1)
    ), 0) INTO v_total_slots
    FROM app_settings, jsonb_array_elements(exam_schedule) AS slot
    WHERE app_settings.id = 1;

    -- استعلام واحد بدلاً من استعلامين
    SELECT COUNT(*) FILTER (WHERE exam_date IS NOT NULL AND exam_hour IS NOT NULL), COUNT(*)
    INTO v_filled_slots, v_total_students
    FROM students;

    RETURN QUERY
    SELECT
        s.is_registration_open,
        (v_total_slots > v_filled_slots),
        s.is_result_query_open,
        s.is_ceremony_query_open,
        s.result_query_open_date,
        s.ceremony_query_open_date,
        s.competition_title,
        v_total_slots,
        v_filled_slots,
        v_total_students
    FROM app_settings s
    WHERE s.id = 1;
END;
$$;

-- 3. صلاحيات الدالة
GRANT EXECUTE ON FUNCTION public_get_registration_status() TO anon, authenticated;
