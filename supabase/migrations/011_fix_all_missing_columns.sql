-- =============================================
-- Migration: إضافة جميع الأعمدة المفقودة وإعادة إنشاء دوال RPC
-- =============================================

-- 1. إضافة selected_rewaya إلى students لو مش موجود
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'students'
                   AND column_name = 'selected_rewaya') THEN
        ALTER TABLE students ADD COLUMN selected_rewaya TEXT;
    END IF;
END $$;

-- 2. إضافة max_score إلى competition_levels لو مش موجود
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'competition_levels'
                   AND column_name = 'max_score') THEN
        ALTER TABLE competition_levels ADD COLUMN max_score INTEGER DEFAULT 100;
    END IF;
END $$;

-- 3. إضافة result_query_open_date و ceremony_query_open_date إلى app_settings لو مش موجودين
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'app_settings'
                   AND column_name = 'result_query_open_date') THEN
        ALTER TABLE app_settings ADD COLUMN result_query_open_date TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'app_settings'
                   AND column_name = 'ceremony_query_open_date') THEN
        ALTER TABLE app_settings ADD COLUMN ceremony_query_open_date TIMESTAMPTZ;
    END IF;
END $$;

-- 4. إعادة إنشاء public_lookup_student
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

-- 5. إعادة إنشاء public_lookup_result
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
    selected_rewaya   TEXT,
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
        s.selected_rewaya,
        cl.level_code, cl.first_prize, cl.second_prize, cl.third_prize, cl.max_score
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_result(TEXT) TO anon, authenticated;

-- 6. إعادة إنشاء public_lookup_ceremony
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
