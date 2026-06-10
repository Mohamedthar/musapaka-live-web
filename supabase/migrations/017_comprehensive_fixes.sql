-- =================================================================================================
-- Migration 017 — إصلاحات شاملة (Comprehensive Fixes)
-- =================================================================================================
-- تاريخ: 2026-06-10
-- يطبق الإصلاحات التالية:
--   1. دمج 3 دوال updated_at في دالة واحدة set_updated_at()
--   2. إضافة دوال مساعدة: calculate_total_score, calculate_max_score, get_student_code_prefix
--   3. إصلاح assign_exam_slot: FIFO حقيقي + استعلام GROUP BY واحد بدل N+1
--   4. إصلاح check_level_capacity: استخدام level_id بدل النص
--   5. إصلاح generate_student_code: regex بدل LIKE + استخدام الدوال المساعدة
--   6. إصلاح regenerate_student_code_on_level_change: استخدام الدوال المساعدة
--   7. إصلاح تصادم الأقفال: ceremony codes يستخدم 987654324 (منفصل عن جدولة الامتحان)
--   8. إصلاح generate_all_ceremony_codes: UPDATE مجمع بدل N+1 + دوال مساعدة
--   9. تحديث public_lookup_ceremony: استخدام الدوال المساعدة
--  10. قيد passing_percentage (1-100)
--  11. قيد app_settings صف وحيد (id = 1)
--  12. قيد ترتيب تواريخ التسجيل
--  13. حذف students_age_check (العمر يحسب من birth_date)
--  14. فهارس مركبة جديدة للأداء
-- =================================================================================================

-- -------------------------------------------------------------------
-- 1. دوال مساعدة مشتركة
-- -------------------------------------------------------------------

-- 1.1 تحديث تلقائي موحد لـ updated_at (بدل 3 دوال متطابقة)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- استبدال المحفزات القديمة لاستخدام الدالة الموحدة
DROP TRIGGER IF EXISTS update_students_updated_at ON students;
CREATE TRIGGER update_students_updated_at
    BEFORE UPDATE ON students FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_app_settings_updated_at ON app_settings;
CREATE TRIGGER trg_app_settings_updated_at
    BEFORE UPDATE ON app_settings FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_levels_updated_at ON competition_levels;
CREATE TRIGGER trg_levels_updated_at
    BEFORE UPDATE ON competition_levels FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- حذف الدوال القديمة غير المستخدمة
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS update_app_settings_updated_at();
DROP FUNCTION IF EXISTS trigger_update_timestamp_competition_levels();

-- 1.2 احتساب مجموع درجات الطالب
CREATE OR REPLACE FUNCTION calculate_total_score(p_student students)
RETURNS DOUBLE PRECISION AS $$
BEGIN
    RETURN COALESCE(p_student.score, 0) + COALESCE(p_student.rewaya_score, 0) +
           COALESCE(p_student.tajweed_score, 0) + COALESCE(p_student.voice_score, 0) +
           COALESCE(p_student.meaning_score, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 1.3 احتساب أقصى درجات المستوى
CREATE OR REPLACE FUNCTION calculate_max_score(p_level competition_levels)
RETURNS INTEGER AS $$
BEGIN
    RETURN COALESCE(p_level.total_points, 100) +
           COALESCE(CASE WHEN p_level.has_rewaya THEN p_level.rewaya_max_score ELSE 0 END, 0) +
           COALESCE(CASE WHEN p_level.has_tajweed THEN p_level.tajweed_max_score ELSE 0 END, 0) +
           COALESCE(CASE WHEN p_level.has_voice THEN p_level.voice_max_score ELSE 0 END, 0) +
           COALESCE(CASE WHEN p_level.has_meaning THEN p_level.meaning_max_score ELSE 0 END, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 1.4 توليد بادئة كود الطالب (حرف المستوى + رقم الجنس)
CREATE OR REPLACE FUNCTION get_student_code_prefix(p_level TEXT, p_gender TEXT)
RETURNS TEXT AS $$
DECLARE
    v_level_code CHAR(1);
    v_gender_num CHAR(1);
BEGIN
    SELECT level_code INTO v_level_code FROM competition_levels WHERE title = p_level LIMIT 1;
    IF v_level_code IS NULL THEN v_level_code := 'X'; END IF;
    v_gender_num := CASE WHEN p_gender = 'ذكر' THEN '1' WHEN p_gender = 'أنثى' THEN '0' ELSE '9' END;
    RETURN v_level_code || v_gender_num;
END;
$$ LANGUAGE plpgsql STABLE;


-- -------------------------------------------------------------------
-- 2. إصلاح assign_exam_slot — FIFO حقيقي + GROUP BY واحد
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

    -- استعلام واحد مجمع بدلاً من N+1 لكل ساعة
    SELECT jsonb_object_agg(exam_date::TEXT || '_' || exam_hour::TEXT, cnt)
    INTO v_slot_counts_json
    FROM (
        SELECT exam_date, exam_hour, COUNT(*) AS cnt
        FROM students
        WHERE exam_date IS NOT NULL AND exam_hour IS NOT NULL
        GROUP BY exam_date, exam_hour
    ) sub;

    FOR slot IN
        SELECT value FROM jsonb_array_elements(schedule_json)
        ORDER BY (value->>'date')::DATE ASC, (value->>'start_hour')::INT ASC
    LOOP
        v_date              := (slot->>'date')::DATE;
        v_start_hour        := (slot->>'start_hour')::INT;
        v_end_hour          := (slot->>'end_hour')::INT;
        v_students_per_hour := (slot->>'students_per_hour')::INT;

        -- FIFO حقيقي: ابدأ من أول ساعة في اليوم
        v_current_hour := v_start_hour;

        WHILE v_current_hour < v_end_hour LOOP
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
            v_current_hour := v_current_hour + 1;
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
-- 3. إصلاح check_level_capacity — استخدام level_id
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_level_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_capacity INTEGER;
    v_current  INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(987654325);

    SELECT max_capacity INTO v_capacity FROM competition_levels WHERE id = NEW.level_id;

    IF v_capacity IS NOT NULL THEN
        SELECT COUNT(*) INTO v_current FROM students WHERE level_id = NEW.level_id;
        IF v_current >= v_capacity THEN
            RAISE EXCEPTION 'المستوى المطلوب ممتلئ تماماً بالحد الأقصى للمتسابقين';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- -------------------------------------------------------------------
-- 4. إصلاح generate_student_code — regex + دالة مساعدة
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_student_code()
RETURNS TRIGGER AS $$
DECLARE
    v_prefix TEXT;
    v_seq    INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(987654322);
    v_prefix := get_student_code_prefix(NEW.level, NEW.gender);

    SELECT COALESCE(
        (SELECT e.seq + 1
         FROM (
             SELECT SUBSTRING(student_code, 3)::int AS seq
             FROM students WHERE student_code ~ ('^' || v_prefix || '\d{3}$')
             UNION ALL SELECT 0
         ) e
         WHERE NOT EXISTS (
             SELECT 1 FROM students WHERE student_code = v_prefix || LPAD((e.seq + 1)::TEXT, 3, '0')
         )
         ORDER BY e.seq LIMIT 1),
        1
    ) INTO v_seq;

    NEW.student_code := v_prefix || LPAD(v_seq::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- -------------------------------------------------------------------
-- 5. إصلاح regenerate_student_code_on_level_change — دالة مساعدة
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION regenerate_student_code_on_level_change()
RETURNS TRIGGER AS $$
DECLARE
    v_prefix TEXT;
    v_seq    INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(987654323);
    v_prefix := get_student_code_prefix(NEW.level, NEW.gender);

    SELECT COALESCE(
        (SELECT e.seq + 1
         FROM (
             SELECT SUBSTRING(student_code, 3)::int AS seq
             FROM students WHERE student_code ~ ('^' || v_prefix || '\d{3}$') AND id != OLD.id
             UNION ALL SELECT 0
         ) e
         WHERE NOT EXISTS (
             SELECT 1 FROM students
             WHERE student_code = v_prefix || LPAD((e.seq + 1)::TEXT, 3, '0') AND id != OLD.id
         )
         ORDER BY e.seq LIMIT 1),
        1
    ) INTO v_seq;

    NEW.student_code := v_prefix || LPAD(v_seq::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- -------------------------------------------------------------------
-- 6. إصلاح public_lookup_ceremony — دوال مساعدة
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public_lookup_ceremony(p_national_id TEXT)
RETURNS TABLE (
    id                INTEGER,
    name              TEXT,
    level             TEXT,
    level_content     TEXT,
    ceremony_code     TEXT,
    profile_image_url TEXT,
    age               INTEGER,
    student_code      TEXT,
    exam_date         DATE,
    exam_hour         INTEGER,
    level_code        CHAR(1),
    first_prize       TEXT,
    second_prize      TEXT,
    third_prize       TEXT,
    is_eligible       BOOLEAN,
    percentage        DOUBLE PRECISION,
    total_score       DOUBLE PRECISION,
    max_score         INTEGER
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_is_open BOOLEAN;
BEGIN
    SELECT is_ceremony_query_open INTO v_is_open FROM app_settings WHERE app_settings.id = 1;
    IF v_is_open IS NOT TRUE THEN
        RAISE EXCEPTION 'الاستعلام عن الحفل غير متاح حالياً.';
    END IF;

    RETURN QUERY
    WITH score_data AS (
        SELECT
            s.id,
            s.name,
            s.level,
            cl.content AS level_content,
            s.ceremony_code,
            s.profile_image_url,
            s.age,
            s.student_code,
            s.exam_date,
            s.exam_hour,
            cl.level_code,
            cl.first_prize,
            cl.second_prize,
            cl.third_prize,
            calculate_total_score(s) AS total_score,
            calculate_max_score(cl) AS max_score,
            COALESCE(cl.passing_percentage, 95) AS passing_pct
        FROM students s
        LEFT JOIN competition_levels cl ON cl.id = s.level_id
        WHERE s.national_id = p_national_id
          AND s.ceremony_code IS NOT NULL
    )
    SELECT
        sd.id,
        sd.name,
        sd.level,
        sd.level_content,
        sd.ceremony_code,
        sd.profile_image_url,
        sd.age,
        sd.student_code,
        sd.exam_date,
        sd.exam_hour,
        sd.level_code,
        sd.first_prize,
        sd.second_prize,
        sd.third_prize,
        CASE WHEN sd.max_score > 0 THEN (sd.total_score * 100.0 / sd.max_score) >= COALESCE(sd.passing_pct, 95) ELSE false END AS is_eligible,
        CASE WHEN sd.max_score > 0 THEN (sd.total_score * 100.0 / sd.max_score) ELSE 0 END AS percentage,
        sd.total_score,
        sd.max_score
    FROM score_data sd;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_ceremony(TEXT) TO anon, authenticated;


-- -------------------------------------------------------------------
-- 7. إصلاح generate_all_ceremony_codes — UPDATE مجمع + قفل منفصل
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_all_ceremony_codes()
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    total_count INTEGER := 0;
BEGIN
    IF is_admin() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح لك بتنفيذ هذا الإجراء.';
    END IF;

    SELECT COUNT(*) INTO total_count FROM students;
    IF total_count = 0 THEN
        RAISE EXCEPTION 'لا يوجد طلاب مسجلين في النظام. قم بإضافة طلاب أولاً.';
    END IF;

    -- قفل منفصل (987654324) لتجنب التصادم مع جدولة الامتحان (987654321)
    PERFORM pg_advisory_xact_lock(987654324);

    -- مسح الأكواد القديمة
    UPDATE students SET ceremony_code = NULL WHERE ceremony_code IS NOT NULL;

    -- UPDATE مجمع واحد بدلاً من N+1 تحديثات منفردة
    WITH level_order AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS lev_num
        FROM competition_levels
    ),
    ranked AS (
        SELECT
            s.id,
            s.gender,
            lo.lev_num,
            calculate_total_score(s) AS total_score,
            calculate_max_score(cl) AS max_points,
            COALESCE(cl.passing_percentage, 95) AS passing_pct,
            ROW_NUMBER() OVER (
                PARTITION BY s.level_id
                ORDER BY calculate_total_score(s) DESC
            ) AS rank_in_level
        FROM students s
        JOIN competition_levels cl ON cl.id = s.level_id
        JOIN level_order lo ON lo.id = s.level_id
        WHERE s.level_id IS NOT NULL
    ),
    with_percentage AS (
        SELECT *,
            CASE WHEN max_points > 0 THEN (total_score * 100.0 / max_points) ELSE 0 END AS percentage
        FROM ranked
    ),
    with_codes AS (
        SELECT
            id,
            CASE WHEN gender = 'ذكر' THEN 'M' ELSE 'F' END || '-' ||
            LPAD(lev_num::TEXT, 2, '0') || '-' ||
            CASE
                WHEN lev_num <= 9 THEN
                    CASE WHEN (CASE WHEN max_points > 0 THEN (total_score * 100.0 / max_points) ELSE 0 END) >= COALESCE(passing_pct, 95)
                         THEN 'S' ELSE 'C' END
                ELSE
                    CASE WHEN rank_in_level <= 3 THEN 'S' ELSE 'C' END
            END || '-' ||
            LPAD((ROW_NUMBER() OVER (ORDER BY lev_num, total_score DESC) + 49)::TEXT, 3, '0') AS ceremony_code
        FROM with_percentage
    )
    UPDATE students s
    SET ceremony_code = wc.ceremony_code
    FROM with_codes wc
    WHERE s.id = wc.id;
END;
$$;

COMMENT ON FUNCTION generate_all_ceremony_codes() IS 'توليد أكواد الحفل. الأهلية: percentage >= passing_percentage للمستويات 1-9، وأفضل 3 للمستويات 10+. تستخدم قفل 987654324.';
GRANT EXECUTE ON FUNCTION generate_all_ceremony_codes() TO authenticated;


-- -------------------------------------------------------------------
-- 8. قيود جديدة
-- -------------------------------------------------------------------

-- 8.1 نطاق passing_percentage (1-100)
ALTER TABLE competition_levels DROP CONSTRAINT IF EXISTS levels_passing_pct_range;
ALTER TABLE competition_levels ADD CONSTRAINT levels_passing_pct_range
    CHECK (passing_percentage IS NULL OR (passing_percentage >= 1 AND passing_percentage <= 100));

-- 8.2 جدول الإعدادات صف وحيد فقط
ALTER TABLE app_settings DROP CONSTRAINT IF EXISTS app_settings_single_row;
ALTER TABLE app_settings ADD CONSTRAINT app_settings_single_row CHECK (id = 1);

-- 8.3 ترتيب تواريخ التسجيل
ALTER TABLE app_settings DROP CONSTRAINT IF EXISTS app_settings_registration_dates;
ALTER TABLE app_settings ADD CONSTRAINT app_settings_registration_dates CHECK (
    registration_end_date IS NULL OR registration_start_date IS NULL OR registration_end_date >= registration_start_date
);

-- 8.4 حذف قيد students_age_check (العمر يحسب من birth_date حسب migration 015)
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_age_check;


-- -------------------------------------------------------------------
-- 9. فهارس مركبة جديدة للأداء
-- -------------------------------------------------------------------

-- فهرس مركب لترتيب أداء الطلاب داخل كل مستوى (يستخدم في generate_all_ceremony_codes)
CREATE INDEX IF NOT EXISTS idx_students_level_id_score
    ON students(level_id, score DESC NULLS LAST);

-- فهرس مركب لاستعلام national_id + student_code معاً (يستخدم في get_student_status)
CREATE INDEX IF NOT EXISTS idx_students_nid_student_code
    ON students(national_id, student_code);


-- =================================================================================================
-- للتأكد من نجاح الترحيل، شغّل:
-- SELECT 'Migration 017 applied' AS status;
-- =================================================================================================
