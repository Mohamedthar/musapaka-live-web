-- =============================================
-- Migration: إصلاح استعلام الحفل مع حساب الأهلية
-- =============================================
-- المشكلة: public_lookup_ceremony كانت لا تحسب النسبة المئوية
-- ولا ترجع is_eligible، مما جعل all students يرون رسالة "نسبتك أقل من 95%"
-- =============================================

-- 1. إعادة إنشاء public_lookup_ceremony مع حساب النسبة المئوية والأهلية
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
             COALESCE(CASE WHEN cl.has_meaning THEN cl.meaning_max_score ELSE 0 END, 0)) AS max_score
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
        CASE WHEN sd.max_score > 0 THEN (sd.total_score * 100.0 / sd.max_score) >= 95 ELSE false END AS is_eligible,
        CASE WHEN sd.max_score > 0 THEN (sd.total_score * 100.0 / sd.max_score) ELSE 0 END AS percentage,
        sd.total_score,
        sd.max_score
    FROM score_data sd;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_ceremony(TEXT) TO anon, authenticated;

-- 2. تحديث دالة generate_all_ceremony_codes لتكون متسقة مع نفس منطق الاحتساب
-- (هي بالفعل تستخدم >= 95، فقط نضيف تعليق توثيقي للاتساق)
COMMENT ON FUNCTION generate_all_ceremony_codes() IS 'توليد أكواد الحفل. الأهلية: percentage >= 95% للمستويات 1-9، وأفضل 3 للمستويات 10+';
