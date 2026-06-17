-- Migration: Remove birth_certificate_url from public_lookup_student function
-- Purpose: Revert - birth certificate image no longer needed in inquiry response

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
    memorizer_phone   TEXT,
    memorizer_address TEXT,
    location          TEXT,
    birth_date        DATE,
    selected_rewaya   TEXT,
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
        s.memorizer_phone, s.memorizer_address, s.location,
        s.birth_date, s.selected_rewaya,
        cl.level_code
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public_lookup_student(TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public_lookup_student(TEXT) TO authenticated;
