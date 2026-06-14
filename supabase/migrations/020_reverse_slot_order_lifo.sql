-- ===================================================================
-- Migration 020: إصلاح شامل لنظام المواعيد
-- ===================================================================
-- 1. عكس ترتيب التوزيع: أول من يسجل = آخر موعد (LIFO بدلاً من FIFO)
-- 2. سد الثقوب فوراً عند حذف طالب لأول مسجل بعد الحذف
-- 3. إصلاح حساب filled_slots في دالة حالة التسجيل
-- ===================================================================

-- -------------------------------------------------------------------
-- 1. دالة توزيع المواعيد (LIFO + سد الثقوب)
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION assign_exam_slot()
RETURNS TRIGGER AS $$
DECLARE
    schedule_json  JSONB;
    slot           JSONB;
    v_date         DATE;
    v_start_hour   INT;
    v_end_hour     INT;
    v_students_per_hour INT;
    v_current_hour INT;
    assigned       BOOLEAN := FALSE;
    v_slot_counts_json JSONB;
BEGIN
    PERFORM pg_advisory_xact_lock(987654321);
    SELECT exam_schedule INTO schedule_json FROM app_settings WHERE id = 1 LIMIT 1;

    IF schedule_json IS NULL OR jsonb_array_length(schedule_json) = 0 THEN
        NEW.notes := COALESCE(NEW.notes || E'\n', '') || 'تنبيه: لم يتم تحديد ميعاد (لا يوجد جدول)';
        RETURN NEW;
    END IF;

    SELECT jsonb_object_agg(exam_date::TEXT || '_' || exam_hour::TEXT, cnt)
    INTO v_slot_counts_json
    FROM (
        SELECT exam_date, exam_hour, COUNT(*) AS cnt
        FROM students
        WHERE exam_date IS NOT NULL AND exam_hour IS NOT NULL
        GROUP BY exam_date, exam_hour
    ) sub;

    -- ================================================================
    -- المرحلة الأولى: سد الثقوب (ترتيب زمني تصاعدي)
    -- الثقب = ساعة فيها طلاب (> 0) ولكن أقل من السعة (نتيجة حذف)
    -- ================================================================
    FOR slot IN
        SELECT value FROM jsonb_array_elements(schedule_json)
        ORDER BY (value->>'date')::DATE ASC, (value->>'start_hour')::INT ASC
    LOOP
        v_date              := (slot->>'date')::DATE;
        v_start_hour        := (slot->>'start_hour')::INT;
        v_end_hour          := (slot->>'end_hour')::INT;
        v_students_per_hour := (slot->>'students_per_hour')::INT;

        v_current_hour := v_start_hour;
        WHILE v_current_hour < v_end_hour LOOP
            DECLARE
                cnt BIGINT;
            BEGIN
                cnt := COALESCE((v_slot_counts_json->>(v_date::TEXT || '_' || v_current_hour::TEXT))::BIGINT, 0);
                -- ثقب حقيقي: فيه طلاب بس أقل من السعة (تم حذف بعضهم)
                IF cnt > 0 AND cnt < v_students_per_hour THEN
                    NEW.exam_date := v_date;
                    NEW.exam_hour := v_current_hour;
                    assigned := TRUE;
                    EXIT;
                END IF;
            END;
            v_current_hour := v_current_hour + 1;
        END LOOP;
        IF assigned THEN EXIT; END IF;
    END LOOP;

    -- ================================================================
    -- المرحلة الثانية: توزيع LIFO من النهاية
    -- ================================================================
    IF NOT assigned THEN
        FOR slot IN
            SELECT value FROM jsonb_array_elements(schedule_json)
            ORDER BY (value->>'date')::DATE DESC, (value->>'start_hour')::INT DESC
        LOOP
            v_date              := (slot->>'date')::DATE;
            v_start_hour        := (slot->>'start_hour')::INT;
            v_end_hour          := (slot->>'end_hour')::INT;
            v_students_per_hour := (slot->>'students_per_hour')::INT;

            v_current_hour := v_end_hour - 1;
            WHILE v_current_hour >= v_start_hour LOOP
                DECLARE
                    cnt BIGINT;
                BEGIN
                    cnt := COALESCE((v_slot_counts_json->>(v_date::TEXT || '_' || v_current_hour::TEXT))::BIGINT, 0);
                    IF cnt < v_students_per_hour THEN
                        NEW.exam_date := v_date;
                        NEW.exam_hour := v_current_hour;
                        assigned := TRUE;
                        EXIT;
                    END IF;
                END;
                v_current_hour := v_current_hour - 1;
            END LOOP;
            IF assigned THEN EXIT; END IF;
        END LOOP;
    END IF;

    IF NOT assigned THEN
        RAISE EXCEPTION 'عذراً، لقد اكتملت جميع المواعيد المتاحة حالياً ولا توجد أماكن شاغرة.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------------
-- 2. إصلاح دالة حالة التسجيل: مطابقة منطق العد مع trigger
--    كان counting فقط exam_date IS NOT NULL
--    والصحيح exam_date IS NOT NULL AND exam_hour IS NOT NULL
-- -------------------------------------------------------------------
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

GRANT EXECUTE ON FUNCTION public_get_registration_status() TO anon, authenticated;
