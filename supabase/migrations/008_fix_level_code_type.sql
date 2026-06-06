-- Fix level_code return type mismatch: competition_levels.level_code is CHAR(1),
-- but RPC functions declared it as TEXT, causing error 42804.
-- Also fix max_score type in public_lookup_result to match competition_levels.max_score (INTEGER).

-- get_student_status
DROP FUNCTION IF EXISTS get_student_status(TEXT, TEXT);
CREATE OR REPLACE FUNCTION get_student_status(p_national_id TEXT, p_student_code TEXT)
RETURNS TABLE (
    id                  INTEGER,
    name                TEXT,
    level               TEXT,
    student_code        TEXT,
    ceremony_code       TEXT,
    exam_date           DATE,
    exam_hour           INTEGER,
    score               DOUBLE PRECISION,
    rewaya_score        DOUBLE PRECISION,
    tajweed_score       DOUBLE PRECISION,
    voice_score         DOUBLE PRECISION,
    meaning_score       DOUBLE PRECISION,
    profile_image_url   TEXT,
    age                 INTEGER,
    gender              TEXT,
    phone               TEXT,
    national_id         TEXT,
    birth_certificate_url TEXT,
    memorizer_name      TEXT,
    memorizer_phone     TEXT,
    memorizer_address   TEXT,
    location            TEXT,
    selected_rewaya     TEXT,
    level_code          CHAR(1),
    first_prize         TEXT,
    second_prize        TEXT,
    third_prize         TEXT
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id, s.name, s.level, s.student_code, s.ceremony_code,
        s.exam_date, s.exam_hour, s.score, s.rewaya_score, s.tajweed_score,
        s.voice_score, s.meaning_score, s.profile_image_url, s.age, s.gender,
        s.phone, s.national_id, s.birth_certificate_url,
        s.memorizer_name, s.memorizer_phone, s.memorizer_address,
        s.location, s.selected_rewaya,
        cl.level_code, cl.first_prize, cl.second_prize, cl.third_prize
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id AND s.student_code = p_student_code;
END;
$$;

GRANT EXECUTE ON FUNCTION get_student_status(TEXT, TEXT) TO authenticated;

-- public_lookup_student
DROP FUNCTION IF EXISTS public_lookup_student(TEXT);
DROP FUNCTION IF EXISTS public_lookup_student(TEXT, TEXT);
CREATE OR REPLACE FUNCTION public_lookup_student(p_national_id TEXT, p_phone TEXT DEFAULT NULL)
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
    WHERE s.national_id = p_national_id
      AND (p_phone IS NULL OR s.phone = p_phone);
END;
$$;

REVOKE EXECUTE ON FUNCTION public_lookup_student(TEXT, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public_lookup_student(TEXT, TEXT) TO authenticated;

-- public_lookup_result
DROP FUNCTION IF EXISTS public_lookup_result(TEXT, TEXT);
CREATE OR REPLACE FUNCTION public_lookup_result(p_national_id TEXT, p_phone TEXT)
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
    WHERE s.national_id = p_national_id AND s.phone = p_phone;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_result(TEXT, TEXT) TO anon, authenticated;

-- public_lookup_ceremony
DROP FUNCTION IF EXISTS public_lookup_ceremony(TEXT, TEXT);
CREATE OR REPLACE FUNCTION public_lookup_ceremony(p_national_id TEXT, p_phone TEXT)
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
      AND s.phone = p_phone
      AND s.ceremony_code IS NOT NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_ceremony(TEXT, TEXT) TO anon, authenticated;
