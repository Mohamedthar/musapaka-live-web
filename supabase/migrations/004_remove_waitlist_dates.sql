-- =============================================
-- Migration: Remove waitlist + date-based registration
-- =============================================

-- 1. إعادة check_level_capacity لرمي exception بدل قائمة الانتظار
CREATE OR REPLACE FUNCTION check_level_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_capacity INTEGER;
    v_current  INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(987654325);
    SELECT max_capacity INTO v_capacity FROM competition_levels WHERE title = NEW.level;

    IF v_capacity IS NOT NULL THEN
        SELECT COUNT(*) INTO v_current FROM students WHERE level = NEW.level;
        IF v_current >= v_capacity THEN
            RAISE EXCEPTION 'المستوى المطلوب ممتلئ تماماً بالحد الأقصى للمتسابقين';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. تحديث public_get_registration_status: إزالة التواريخ، إضافة has_available_slots
DROP FUNCTION IF EXISTS public_get_registration_status();
CREATE OR REPLACE FUNCTION public_get_registration_status()
RETURNS TABLE (
    is_registration_open     BOOLEAN,
    has_available_slots      BOOLEAN,
    is_result_query_open     BOOLEAN,
    is_ceremony_query_open   BOOLEAN,
    result_query_open_date   TIMESTAMPTZ,
    ceremony_query_open_date TIMESTAMPTZ,
    competition_title        TEXT,
    total_slots              BIGINT,
    filled_slots             BIGINT,
    total_students           BIGINT
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
    WHERE id = 1;

    SELECT COUNT(*) INTO v_filled_slots FROM students WHERE exam_date IS NOT NULL;
    SELECT COUNT(*) INTO v_total_students FROM students;

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

GRANT EXECUTE ON FUNCTION public_get_registration_status() TO anon, authenticated;
