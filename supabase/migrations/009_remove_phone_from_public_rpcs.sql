-- Remove phone parameter from public inquiry RPC functions.
-- Students can now search by national ID only.

-- public_lookup_student — just national ID
DROP FUNCTION IF EXISTS public_lookup_student(TEXT, TEXT);
DROP FUNCTION IF EXISTS public_lookup_student(TEXT);
CREATE OR REPLACE FUNCTION public_lookup_student(p_national_id TEXT)
RETURNS TABLE (
    id                INTEGER,
    name              TEXT,
    level             TEXT,
    student_code      TEXT,
    ceremony_code     TEXT,
    exam_date         DATE,
    exam_hour         INTEGER,
    score             DOUBLE PRECISION,
    profile_image_url TEXT,
    age               INTEGER,
    gender            TEXT,
    phone             TEXT,
    national_id       TEXT,
    memorizer_name    TEXT,
    level_code        CHAR(1)
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id, s.name, s.level, s.student_code, s.ceremony_code,
        s.exam_date, s.exam_hour, s.score, s.profile_image_url,
        s.age, s.gender, s.phone, s.national_id, s.memorizer_name,
        cl.level_code
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public_lookup_student(TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public_lookup_student(TEXT) TO authenticated;

-- public_lookup_result — just national ID
DROP FUNCTION IF EXISTS public_lookup_result(TEXT, TEXT);
DROP FUNCTION IF EXISTS public_lookup_result(TEXT);
CREATE OR REPLACE FUNCTION public_lookup_result(p_national_id TEXT)
RETURNS TABLE (
    id                INTEGER,
    name              TEXT,
    level             TEXT,
    student_code      TEXT,
    ceremony_code     TEXT,
    exam_date         DATE,
    exam_hour         INTEGER,
    score               DOUBLE PRECISION,
    rewaya_score        DOUBLE PRECISION,
    tajweed_score       DOUBLE PRECISION,
    voice_score         DOUBLE PRECISION,
    meaning_score       DOUBLE PRECISION,
    profile_image_url TEXT,
    age               INTEGER,
    gender            TEXT,
    level_code        CHAR(1),
    first_prize       TEXT,
    second_prize      TEXT,
    third_prize       TEXT,
    max_score         INTEGER
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id, s.name, s.level, s.student_code, s.ceremony_code,
        s.exam_date, s.exam_hour, s.score, s.rewaya_score, s.tajweed_score,
        s.voice_score, s.meaning_score, s.profile_image_url, s.age, s.gender,
        cl.level_code, cl.first_prize, cl.second_prize, cl.third_prize, cl.max_score
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_result(TEXT) TO anon, authenticated;

-- public_lookup_ceremony — just national ID
DROP FUNCTION IF EXISTS public_lookup_ceremony(TEXT, TEXT);
DROP FUNCTION IF EXISTS public_lookup_ceremony(TEXT);
CREATE OR REPLACE FUNCTION public_lookup_ceremony(p_national_id TEXT)
RETURNS TABLE (
    id                INTEGER,
    name              TEXT,
    level             TEXT,
    ceremony_code     TEXT,
    profile_image_url TEXT,
    age               INTEGER,
    student_code      TEXT,
    exam_date         DATE,
    exam_hour         INTEGER,
    level_code        CHAR(1),
    first_prize       TEXT,
    second_prize      TEXT,
    third_prize       TEXT
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_is_open BOOLEAN;
BEGIN
    SELECT is_ceremony_query_open INTO v_is_open FROM app_settings WHERE id = 1;
    IF v_is_open IS NOT TRUE THEN
        RAISE EXCEPTION 'الاستعلام عن الحفل غير متاح حالياً.';
    END IF;

    RETURN QUERY
    SELECT
        s.id, s.name, s.level, s.ceremony_code, s.profile_image_url,
        s.age, s.student_code, s.exam_date, s.exam_hour,
        cl.level_code, cl.first_prize, cl.second_prize, cl.third_prize
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id
      AND s.ceremony_code IS NOT NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_ceremony(TEXT) TO anon, authenticated;
