-- ============================================================
-- ملف موحد: جميع تعديلات وتحسينات قاعدة البيانات
-- Consolidated: All Database Fixes & Improvements
-- ============================================================
-- للتشغيل: انسخ هذا الملف بالكامل في Supabase SQL Editor
-- Run: Copy entire file into Supabase SQL Editor
-- ============================================================

BEGIN;

-- ============================================================
-- القسم 1: تحسين check_level_capacity (قفل استشاري)
-- Fix: Race condition via advisory lock
-- ============================================================
CREATE OR REPLACE FUNCTION check_level_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_capacity INTEGER;
    v_current INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(987654325);

    SELECT max_capacity INTO v_capacity FROM competition_levels WHERE title = NEW.level;
    IF v_capacity IS NOT NULL THEN
        SELECT COUNT(*) INTO v_current FROM students WHERE level = NEW.level;
        IF v_current >= v_capacity THEN
            RAISE EXCEPTION 'المستوى المطلوب ممتلئ تماماً بالحد الأقصى للمتسابقين';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- القسم 2: توحيد ON DELETE RESTRICT على fk_students_level
-- Fix: Consistent FK behavior with migration
-- ============================================================
ALTER TABLE students DROP CONSTRAINT IF EXISTS fk_students_level;

ALTER TABLE students ADD CONSTRAINT fk_students_level
    FOREIGN KEY (level) REFERENCES competition_levels(title)
    ON DELETE RESTRICT;

-- ============================================================
-- القسم 3: تحسين generate_student_code (gap-finding فعال)
-- Fix: Performance - no more generate_series(1,9999)
-- ============================================================
CREATE OR REPLACE FUNCTION generate_student_code()
RETURNS TRIGGER AS $$
DECLARE
    v_level_code  CHAR(1);
    v_gender_num  CHAR(1);
    v_seq         INTEGER;
    v_prefix      TEXT;
BEGIN
    PERFORM pg_advisory_xact_lock(987654322);

    SELECT level_code INTO v_level_code FROM competition_levels WHERE title = NEW.level LIMIT 1;
    IF v_level_code IS NULL THEN v_level_code := 'X'; END IF;

    v_gender_num := CASE WHEN NEW.gender = 'ذكر' THEN '1' WHEN NEW.gender = 'أنثى' THEN '0' ELSE '9' END;
    v_prefix := v_level_code || v_gender_num;

    SELECT COALESCE(
        (SELECT e.seq + 1
         FROM (
             SELECT SUBSTRING(student_code, 3)::int AS seq
             FROM students
             WHERE student_code LIKE v_prefix || '___'
             UNION ALL SELECT 0
         ) e
         WHERE NOT EXISTS (
             SELECT 1 FROM students
             WHERE student_code = v_prefix || LPAD((e.seq + 1)::TEXT, 3, '0')
         )
         ORDER BY e.seq
         LIMIT 1),
        1
    ) INTO v_seq;

    NEW.student_code := v_prefix || LPAD(v_seq::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- القسم 4: تحسين regenerate_student_code_on_level_change
-- Fix: Performance - no more generate_series(1,9999)
-- ============================================================
CREATE OR REPLACE FUNCTION regenerate_student_code_on_level_change()
RETURNS TRIGGER AS $$
DECLARE
    v_level_code  CHAR(1);
    v_gender_num  CHAR(1);
    v_seq         INTEGER;
    v_prefix      TEXT;
BEGIN
    PERFORM pg_advisory_xact_lock(987654323);

    SELECT level_code INTO v_level_code FROM competition_levels WHERE title = NEW.level LIMIT 1;
    IF v_level_code IS NULL THEN v_level_code := 'X'; END IF;

    v_gender_num := CASE WHEN NEW.gender = 'ذكر' THEN '1' WHEN NEW.gender = 'أنثى' THEN '0' ELSE '9' END;
    v_prefix := v_level_code || v_gender_num;

    SELECT COALESCE(
        (SELECT e.seq + 1
         FROM (
             SELECT SUBSTRING(student_code, 3)::int AS seq
             FROM students
             WHERE student_code LIKE v_prefix || '___'
               AND id != OLD.id
             UNION ALL SELECT 0
         ) e
         WHERE NOT EXISTS (
             SELECT 1 FROM students
             WHERE student_code = v_prefix || LPAD((e.seq + 1)::TEXT, 3, '0')
               AND id != OLD.id
         )
         ORDER BY e.seq
         LIMIT 1),
        1
    ) INTO v_seq;

    NEW.student_code := v_prefix || LPAD(v_seq::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- القسم 5: إصلاح generate_all_ceremony_codes (درجات كاملة)
-- Fix: Include rewaya/tajweed/voice/meaning in eligibility calc
-- ============================================================
CREATE OR REPLACE FUNCTION generate_all_ceremony_codes()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF pg_try_advisory_xact_lock(987654324) = FALSE THEN
        RAISE EXCEPTION 'عملية توليد الأكواد جارية بالفعل، يرجى المحاولة لاحقاً.';
    END IF;

    UPDATE students SET ceremony_code = NULL WHERE id IS NOT NULL;

    WITH honored_students AS (
        SELECT 
            s.id,
            s.gender,
            s.age,
            COALESCE(ASCII(c.level_code) - 64, 24) AS level_num,
            (
                COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0)
            ) AS total_score,
            DENSE_RANK() OVER (PARTITION BY s.level_id ORDER BY (
                COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0)
            ) DESC) as level_rank,
            ROW_NUMBER() OVER (ORDER BY COALESCE(ASCII(c.level_code), 88) ASC, (
                COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0)
            ) DESC, s.name ASC) as global_seq
        FROM students s
        JOIN competition_levels c ON c.id = s.level_id
        WHERE (
            c.total_points + 
            CASE WHEN c.has_rewaya THEN COALESCE(c.rewaya_max_score, 0) ELSE 0 END +
            CASE WHEN c.has_tajweed THEN COALESCE(c.tajweed_max_score, 0) ELSE 0 END +
            CASE WHEN c.has_voice THEN COALESCE(c.voice_max_score, 0) ELSE 0 END +
            CASE WHEN c.has_meaning THEN COALESCE(c.meaning_max_score, 0) ELSE 0 END
        ) > 0
          AND (
            (COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0))::NUMERIC / 
            (
                c.total_points + 
                CASE WHEN c.has_rewaya THEN COALESCE(c.rewaya_max_score, 0) ELSE 0 END +
                CASE WHEN c.has_tajweed THEN COALESCE(c.tajweed_max_score, 0) ELSE 0 END +
                CASE WHEN c.has_voice THEN COALESCE(c.voice_max_score, 0) ELSE 0 END +
                CASE WHEN c.has_meaning THEN COALESCE(c.meaning_max_score, 0) ELSE 0 END
            )::NUMERIC * 100
          ) >= 95
    )
    UPDATE students
    SET ceremony_code = 
        CASE WHEN h.gender = 'ذكر' THEN 'M' ELSE 'F' END || '-' || 
        h.level_num::TEXT || '-' ||
        CASE 
            WHEN h.level_num <= 9 THEN 'S'
            WHEN h.age >= 18 THEN 'S'
            WHEN h.level_rank <= 3 THEN 'S'
            ELSE 'C' 
        END || '-' ||
        LPAD(h.global_seq::TEXT, 3, '0')
    FROM honored_students h
    WHERE students.id = h.id;
END;
$$;

-- ============================================================
-- القسم 6: إضافة level_id + FK صحيح + trigger تزامن
-- Fix: Replace TEXT FK with proper INTEGER FK
-- ============================================================
ALTER TABLE students ADD COLUMN IF NOT EXISTS level_id INTEGER;

UPDATE students s
SET level_id = cl.id
FROM competition_levels cl
WHERE s.level = cl.title
  AND s.level_id IS NULL;

CREATE OR REPLACE FUNCTION sync_level_id()
RETURNS TRIGGER AS $$
BEGIN
    SELECT id INTO NEW.level_id
    FROM competition_levels
    WHERE title = NEW.level
    LIMIT 1;
    
    IF NEW.level_id IS NULL THEN
        RAISE EXCEPTION 'المستوى "%" غير موجود في جدول competition_levels', NEW.level;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_level_id ON students;
CREATE TRIGGER trg_sync_level_id
    BEFORE INSERT OR UPDATE OF level ON students
    FOR EACH ROW
    EXECUTE FUNCTION sync_level_id();

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_students_level_id') THEN
        ALTER TABLE students ADD CONSTRAINT fk_students_level_id
            FOREIGN KEY (level_id) REFERENCES competition_levels(id)
            ON DELETE RESTRICT;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_students_level_id ON students(level_id);

-- ============================================================
-- القسم 7: إضافة NOT NULL على memorizer_name
-- Fix: Match frontend validation with DB constraint
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_memorizer_name_not_null') THEN
        ALTER TABLE students ALTER COLUMN memorizer_name SET NOT NULL;
    END IF;
END $$;

-- ============================================================
-- القسم 8: حذف البيانات الافتراضية الصلبة من app_settings
-- Fix: Admin manages content, not hardcoded SQL defaults
-- ============================================================
ALTER TABLE app_settings ALTER COLUMN timeline SET DEFAULT '[]'::jsonb;
ALTER TABLE app_settings ALTER COLUMN faqs SET DEFAULT '[]'::jsonb;

-- ============================================================
-- القسم 9: دوال RLS آمنة للاستعلامات العامة (anon key)
-- Fix: API routes use anon key instead of service_role
-- ============================================================

-- 9.1 استعلام عن الاستمارة
CREATE OR REPLACE FUNCTION public_lookup_student(p_national_id TEXT)
RETURNS TABLE (
    id INTEGER,
    student_code TEXT,
    name TEXT,
    phone TEXT,
    national_id TEXT,
    age INTEGER,
    gender TEXT,
    level TEXT,
    level_id INTEGER,
    level_content TEXT,
    selected_rewaya TEXT,
    branch_name TEXT,
    memorization_amount INTEGER,
    memorizer_name TEXT,
    memorizer_phone TEXT,
    memorizer_address TEXT,
    location TEXT,
    birth_date DATE,
    profile_image_url TEXT,
    birth_certificate_url TEXT,
    exam_date DATE,
    exam_hour INTEGER,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id, s.student_code, s.name, s.phone, s.national_id,
        s.age, s.gender, s.level, s.level_id,
        cl.content AS level_content,
        s.selected_rewaya, s.branch_name, s.memorization_amount,
        s.memorizer_name, s.memorizer_phone, s.memorizer_address,
        s.location, s.birth_date,
        s.profile_image_url, s.birth_certificate_url,
        s.exam_date, s.exam_hour, s.created_at
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_student(TEXT) TO anon, authenticated;

-- 9.2 استعلام عن النتيجة
CREATE OR REPLACE FUNCTION public_lookup_result(p_national_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_open BOOLEAN;
    v_result JSONB;
BEGIN
    SELECT is_result_query_open INTO v_is_open FROM app_settings LIMIT 1;
    
    IF v_is_open IS NOT TRUE THEN
        RETURN jsonb_build_object(
            'error', 'قسم الاستعلام عن النتيجة النهائية غير متاح حالياً.',
            'closed', true
        );
    END IF;

    SELECT jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'gender', s.gender,
        'level', s.level,
        'level_content', cl.content,
        'student_code', s.student_code,
        'profile_image_url', s.profile_image_url,
        'score', s.score,
        'rewaya_score', s.rewaya_score,
        'selected_rewaya', s.selected_rewaya,
        'tajweed_score', s.tajweed_score,
        'voice_score', s.voice_score,
        'meaning_score', s.meaning_score,
        'level_info', jsonb_build_object(
            'total_points', cl.total_points,
            'has_rewaya', cl.has_rewaya,
            'rewaya_max_score', cl.rewaya_max_score,
            'has_tajweed', cl.has_tajweed,
            'tajweed_max_score', cl.tajweed_max_score,
            'has_voice', cl.has_voice,
            'voice_max_score', cl.voice_max_score,
            'has_meaning', cl.has_meaning,
            'meaning_max_score', cl.meaning_max_score
        )
    ) INTO v_result
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id
    LIMIT 1;

    IF v_result IS NULL THEN
        RETURN jsonb_build_object(
            'error', 'لم يُعثر على متسابق بهذا الرقم القومي.'
        );
    END IF;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_result(TEXT) TO anon, authenticated;

-- 9.3 استعلام عن الحفل
CREATE OR REPLACE FUNCTION public_lookup_ceremony(p_national_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_open BOOLEAN;
    v_result JSONB;
    v_total_score NUMERIC;
    v_max_score INTEGER;
BEGIN
    SELECT is_ceremony_query_open INTO v_is_open FROM app_settings LIMIT 1;
    
    IF v_is_open IS NOT TRUE THEN
        RETURN jsonb_build_object(
            'error', 'قسم الاستعلام عن حضور الحفل غير متاح حالياً.',
            'closed', true
        );
    END IF;

    SELECT 
        COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0),
        cl.total_points + 
            CASE WHEN cl.has_rewaya THEN COALESCE(cl.rewaya_max_score, 0) ELSE 0 END +
            CASE WHEN cl.has_tajweed THEN COALESCE(cl.tajweed_max_score, 0) ELSE 0 END +
            CASE WHEN cl.has_voice THEN COALESCE(cl.voice_max_score, 0) ELSE 0 END +
            CASE WHEN cl.has_meaning THEN COALESCE(cl.meaning_max_score, 0) ELSE 0 END
    INTO v_total_score, v_max_score
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id
    LIMIT 1;

    IF v_total_score IS NULL THEN
        RETURN jsonb_build_object(
            'error', 'لم يُعثر على متسابق بهذا الرقم القومي.'
        );
    END IF;

    SELECT jsonb_build_object(
        'name', s.name,
        'gender', s.gender,
        'level', s.level,
        'level_content', cl.content,
        'ceremony_code', s.ceremony_code,
        'profile_image_url', s.profile_image_url,
        'is_eligible', CASE WHEN v_max_score > 0 AND (v_total_score / v_max_score * 100) >= 95 THEN true ELSE false END
    ) INTO v_result
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id
    LIMIT 1;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_ceremony(TEXT) TO anon, authenticated;

-- 9.4 حالة التسجيل
CREATE OR REPLACE FUNCTION public_get_registration_status()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'is_open', is_registration_open,
        'start_date', registration_start_date,
        'end_date', registration_end_date,
        'is_result_query_open', is_result_query_open,
        'is_ceremony_query_open', is_ceremony_query_open
    ) INTO v_result
    FROM app_settings LIMIT 1;
    
    RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public_get_registration_status() TO anon, authenticated;

-- 9.5 إحصائيات الصفحة الرئيسية
CREATE OR REPLACE FUNCTION public_get_home_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total_students BIGINT;
    v_active_levels BIGINT;
    v_settings JSONB;
BEGIN
    SELECT COUNT(*) INTO v_total_students FROM students;
    SELECT COUNT(*) INTO v_active_levels FROM competition_levels WHERE is_active = true;
    
    SELECT jsonb_build_object('total_prizes', total_prizes, 'committees_count', committees_count)
    INTO v_settings FROM app_settings LIMIT 1;

    RETURN jsonb_build_object(
        'total_students', v_total_students,
        'active_levels', v_active_levels,
        'total_prizes', COALESCE(v_settings->>'total_prizes', '50,000+'),
        'committees_count', COALESCE((v_settings->>'committees_count')::int, 3)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public_get_home_stats() TO anon, authenticated;

-- ============================================================
-- القسم 10: رسالة خطأ أوضح لحد المستويات
-- Fix: Better error message for max levels
-- ============================================================
CREATE OR REPLACE FUNCTION assign_level_code()
RETURNS TRIGGER AS $$
DECLARE
    v_code_ascii INTEGER;
BEGIN
    SELECT MIN(c.code) INTO v_code_ascii
    FROM generate_series(65, 90) AS c(code)
    WHERE NOT EXISTS (
        SELECT 1 FROM competition_levels WHERE ASCII(level_code) = c.code
    );
    
    IF v_code_ascii IS NULL THEN 
        RAISE EXCEPTION 'وصلت للحد الأقصى للمستويات (26 مستوى - A إلى Z)'; 
    END IF;
    
    NEW.level_code := CHR(v_code_ascii);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- ============================================================
-- تم. جميع التعديلات نشطة.
-- Done. All fixes are live.
-- ============================================================
