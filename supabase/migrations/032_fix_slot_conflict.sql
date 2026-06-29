-- =================================================================================================
-- Migration 032 — إصلاح تداخل التعيين اليدوي مع التلقائي
-- =================================================================================================
-- 1. إزالة مرحلة سد الثقوب من assign_exam_slot() لأنها تتعارض مع التعيين اليدوي
--    LIFO وحده كافٍ لتوزيع عادل، ويملأ الفراغات تلقائياً عندما يصل لها في الترتيب التنازلي
-- 2. تحديث get_slot_availability() لاستبعاد طالب محدد (لحالة التعديل)
-- =================================================================================================

-- -------------------------------------------------------------------
-- 1. إعادة بناء assign_exam_slot() — LIFO فقط (بدون سد الثقوب)
--    المنطق: التوزيع من الأحدث إلى الأقدم، كل ساعة تُملأ قبل الانتقال للي قبلها
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
    v_slot_exists  BOOLEAN;
    v_max_cap      INT;
    v_current_cnt  BIGINT;
BEGIN
    PERFORM pg_advisory_xact_lock(987654321);

    -- ── مسار التعيين اليدوي ──
    IF NEW.exam_date IS NOT NULL AND NEW.exam_hour IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM app_settings, jsonb_array_elements(exam_schedule) AS s
            WHERE app_settings.id = 1
              AND (s->>'date')::DATE = NEW.exam_date
              AND (s->>'start_hour')::INT <= NEW.exam_hour
              AND (s->>'end_hour')::INT > NEW.exam_hour
        ) INTO v_slot_exists;

        IF NOT v_slot_exists THEN
            RAISE EXCEPTION 'الموعد المحدد غير موجود في جدول الاختبارات.';
        END IF;

        SELECT (s->>'students_per_hour')::INT INTO v_max_cap
        FROM app_settings, jsonb_array_elements(exam_schedule) AS s
        WHERE app_settings.id = 1
          AND (s->>'date')::DATE = NEW.exam_date
          AND (s->>'start_hour')::INT <= NEW.exam_hour
          AND (s->>'end_hour')::INT > NEW.exam_hour
        LIMIT 1;

        SELECT COUNT(*) INTO v_current_cnt
        FROM students
        WHERE exam_date = NEW.exam_date AND exam_hour = NEW.exam_hour;

        IF v_current_cnt >= v_max_cap THEN
            RAISE EXCEPTION 'هذا الموعد ممتلئ بالكامل (% طالب من %)', v_current_cnt, v_max_cap;
        END IF;

        RETURN NEW;
    END IF;

    -- ── المسار التلقائي: LIFO فقط ──
    SELECT exam_schedule INTO schedule_json FROM app_settings WHERE id = 1 LIMIT 1;

    IF schedule_json IS NULL OR jsonb_array_length(schedule_json) = 0 THEN
        NEW.notes := COALESCE(NEW.notes || E'\n', '') || 'تنبيه: لم يتم تحديد ميعاد (لا يوجد جدول)';
        RETURN NEW;
    END IF;

    -- خريطة الإشغال الموحدة
    SELECT jsonb_object_agg(exam_date::TEXT || '_' || exam_hour::TEXT, cnt)
    INTO v_slot_counts_json
    FROM (
        SELECT exam_date, exam_hour, COUNT(*) AS cnt
        FROM students
        WHERE exam_date IS NOT NULL AND exam_hour IS NOT NULL
        GROUP BY exam_date, exam_hour
    ) sub;

    -- توزيع LIFO: الأحدث تاريخاً فالأحدث ساعة
    FOR slot IN
        SELECT value FROM jsonb_array_elements(schedule_json)
        ORDER BY (value->>'date')::DATE DESC, (value->>'start_hour')::INT DESC
    LOOP
        v_date              := (slot->>'date')::DATE;
        v_start_hour        := (slot->>'start_hour')::INT;
        v_end_hour          := (slot->>'end_hour')::INT;
        v_students_per_hour := (slot->>'students_per_hour')::INT;

        -- من آخر ساعة إلى أول ساعة في الفترة
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

    IF NOT assigned THEN
        RAISE EXCEPTION 'عذراً، لقد اكتملت جميع المواعيد المتاحة حالياً ولا توجد أماكن شاغرة.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- -------------------------------------------------------------------
-- 2. دالة get_slot_availability() مع معامل اختياري لاستبعاد طالب
--    يُستخدم في وضع التعديل لرؤية الإتاحة الحقيقية بدون الطالب الحالي
-- -------------------------------------------------------------------
DROP FUNCTION IF EXISTS get_slot_availability();
DROP FUNCTION IF EXISTS get_slot_availability(INTEGER);
CREATE OR REPLACE FUNCTION get_slot_availability(p_exclude_student_id INTEGER DEFAULT NULL)
RETURNS TABLE(
    exam_date        DATE,
    exam_hour        INTEGER,
    start_hour       INTEGER,
    end_hour         INTEGER,
    students_per_hour INTEGER,
    current_count    BIGINT,
    is_available     BOOLEAN
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    WITH schedule_slots AS (
        SELECT
            (slot->>'date')::DATE        AS slot_date,
            (slot->>'start_hour')::INT   AS slot_start,
            (slot->>'end_hour')::INT     AS slot_end,
            (slot->>'students_per_hour')::INT AS slot_cap,
            generate_series(
                (slot->>'start_hour')::INT,
                (slot->>'end_hour')::INT - 1
            ) AS slot_hour
        FROM app_settings,
        jsonb_array_elements(exam_schedule) AS slot
        WHERE app_settings.id = 1
    ),
    current_counts AS (
        SELECT exam_date, exam_hour, COUNT(*) AS cnt
        FROM students
        WHERE exam_date IS NOT NULL
          AND exam_hour IS NOT NULL
          AND (p_exclude_student_id IS NULL OR id != p_exclude_student_id)
        GROUP BY exam_date, exam_hour
    )
    SELECT
        ss.slot_date,
        ss.slot_hour,
        ss.slot_start,
        ss.slot_end,
        ss.slot_cap,
        COALESCE(cc.cnt, 0) AS current_count,
        COALESCE(cc.cnt, 0) < ss.slot_cap AS is_available
    FROM schedule_slots ss
    LEFT JOIN current_counts cc
        ON cc.exam_date = ss.slot_date AND cc.exam_hour = ss.slot_hour
    ORDER BY ss.slot_date, ss.slot_hour;
$$;

GRANT EXECUTE ON FUNCTION get_slot_availability(INTEGER) TO authenticated;
