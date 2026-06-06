-- =============================================
-- Migration: إصلاح أنواع score في دوال RPC
-- تغيير NUMERIC → DOUBLE PRECISION لتطابق الجدول الفعلي
-- =============================================

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
    level_code        TEXT
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
    score             DOUBLE PRECISION,
    rewaya_score      DOUBLE PRECISION,
    tajweed_score     DOUBLE PRECISION,
    voice_score       DOUBLE PRECISION,
    meaning_score     DOUBLE PRECISION,
    profile_image_url TEXT,
    age               INTEGER,
    gender            TEXT,
    level_code        TEXT,
    first_prize       TEXT,
    second_prize      TEXT,
    third_prize       TEXT,
    max_score         DOUBLE PRECISION
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
    age                 INTEGER,
    memorizer_name      TEXT,
    memorizer_phone     TEXT,
    memorizer_address   TEXT,
    profile_image_url   TEXT,
    registration_ip     TEXT,
    location            TEXT
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id, s.name, s.level, s.student_code, s.ceremony_code,
        s.exam_date, s.exam_hour, s.score, s.rewaya_score, s.tajweed_score,
        s.voice_score, s.meaning_score, s.age, s.memorizer_name,
        s.memorizer_phone, s.memorizer_address, s.profile_image_url,
        s.registration_ip, s.location
    FROM students s
    WHERE s.national_id = p_national_id
      AND s.student_code = p_student_code;
END;
$$;

GRANT EXECUTE ON FUNCTION get_student_status(TEXT, TEXT) TO authenticated;
