-- =================================================================================================
-- Migration: إضافة نسبة النجاح المئوية لكل مستوى
-- passing_percentage — تسمح لكل مستوى بتحديد نسبة نجاح مختلفة بدلاً من 95% الثابتة
-- تُستخدم في: public_lookup_ceremony, generate_all_ceremony_codes
-- =================================================================================================

-- 1. إضافة العمود
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'competition_levels'
                   AND column_name = 'passing_percentage') THEN
        ALTER TABLE competition_levels ADD COLUMN passing_percentage INTEGER DEFAULT 95;
    END IF;
END $$;

-- 2. تحديث public_lookup_ceremony — استخدام passing_percentage بدل 95 الثابتة
DROP FUNCTION IF EXISTS public_lookup_ceremony(TEXT, TEXT);
DROP FUNCTION IF EXISTS public_lookup_ceremony(TEXT);
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
            (COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + 
             COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + 
             COALESCE(s.meaning_score, 0)) AS total_score,
            (COALESCE(cl.total_points, 100) +
             COALESCE(CASE WHEN cl.has_rewaya THEN cl.rewaya_max_score ELSE 0 END, 0) +
             COALESCE(CASE WHEN cl.has_tajweed THEN cl.tajweed_max_score ELSE 0 END, 0) +
             COALESCE(CASE WHEN cl.has_voice THEN cl.voice_max_score ELSE 0 END, 0) +
             COALESCE(CASE WHEN cl.has_meaning THEN cl.meaning_max_score ELSE 0 END, 0)) AS max_score,
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

-- 3. تحديث generate_all_ceremony_codes — استخدام passing_percentage
CREATE OR REPLACE FUNCTION generate_all_ceremony_codes()
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    student_rec RECORD;
    gender_char TEXT;
    level_num   TEXT;
    stage_char  TEXT;
    global_seq  INTEGER := 50;
    total_count INTEGER := 0;
BEGIN
    IF NOT is_admin() AND auth.uid() IS NOT NULL THEN
        RAISE EXCEPTION 'غير مصرح لك بتنفيذ هذا الإجراء.';
    END IF;

    SELECT COUNT(*) INTO total_count FROM students;
    IF total_count = 0 THEN
        RAISE EXCEPTION 'لا يوجد طلاب مسجلين في النظام. قم بإضافة طلاب أولاً.';
    END IF;

    PERFORM pg_advisory_xact_lock(987654321);

    UPDATE students SET ceremony_code = NULL WHERE ceremony_code IS NOT NULL;

    FOR student_rec IN
        WITH level_order AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS lev_num
            FROM competition_levels
        ),
        ranked_students AS (
            SELECT 
                s.id,
                s.gender,
                lo.lev_num,
                (COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + 
                 COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + 
                 COALESCE(s.meaning_score, 0)) AS total_score,
                (COALESCE(cl.total_points, 100) +
                 COALESCE(CASE WHEN cl.has_rewaya THEN cl.rewaya_max_score ELSE 0 END, 0) +
                 COALESCE(CASE WHEN cl.has_tajweed THEN cl.tajweed_max_score ELSE 0 END, 0) +
                 COALESCE(CASE WHEN cl.has_voice THEN cl.voice_max_score ELSE 0 END, 0) +
                 COALESCE(CASE WHEN cl.has_meaning THEN cl.meaning_max_score ELSE 0 END, 0)) AS max_points,
                COALESCE(cl.passing_percentage, 95) AS passing_pct,
                ROW_NUMBER() OVER (
                    PARTITION BY s.level_id
                    ORDER BY (COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + 
                             COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + 
                             COALESCE(s.meaning_score, 0)) DESC
                ) AS rank_in_level
            FROM students s
            JOIN competition_levels cl ON cl.id = s.level_id
            JOIN level_order lo ON lo.id = s.level_id
            WHERE s.level_id IS NOT NULL
        )
        SELECT *, 
            CASE WHEN max_points > 0 
                 THEN (total_score * 100.0 / max_points) 
                 ELSE 0 
            END AS percentage
        FROM ranked_students
        ORDER BY lev_num, total_score DESC
    LOOP
        gender_char := CASE WHEN student_rec.gender = 'ذكر' THEN 'M' ELSE 'F' END;
        level_num := LPAD(student_rec.lev_num::TEXT, 2, '0');

        IF student_rec.lev_num <= 9 THEN
            stage_char := CASE WHEN student_rec.percentage >= COALESCE(student_rec.passing_pct, 95) THEN 'S' ELSE 'C' END;
        ELSE
            stage_char := CASE WHEN student_rec.rank_in_level <= 3 THEN 'S' ELSE 'C' END;
        END IF;

        UPDATE students
        SET ceremony_code = gender_char || '-' || level_num || '-' || stage_char || '-' || LPAD(global_seq::TEXT, 3, '0')
        WHERE id = student_rec.id;

        global_seq := global_seq + 1;
    END LOOP;
END;
$$;

COMMENT ON FUNCTION generate_all_ceremony_codes() IS 'توليد أكواد الحفل. الأهلية: percentage >= passing_percentage للمستويات 1-9، وأفضل 3 للمستويات 10+';

-- 4. الصلاحيات
GRANT EXECUTE ON FUNCTION public_lookup_ceremony(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION generate_all_ceremony_codes() TO authenticated;
