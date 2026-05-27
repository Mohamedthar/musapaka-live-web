-- =============================================
-- Migration: Full Fixes - تشغيل مرة واحدة على Supabase SQL Editor
-- يحتوي على جميع إصلاحات الأمان والأداء وسلامة البيانات
-- =============================================

BEGIN;

-- =============================================
-- 1. FOREIGN KEY على students.level
-- =============================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_students_level') THEN
        ALTER TABLE students ADD CONSTRAINT fk_students_level
            FOREIGN KEY (level) REFERENCES competition_levels(title)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- =============================================
-- 2. قيد memorization_amount غير سالب
-- =============================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_memorization_non_negative') THEN
        ALTER TABLE students ADD CONSTRAINT students_memorization_non_negative 
            CHECK (memorization_amount >= 0);
    END IF;
END $$;

-- =============================================
-- 3. فهارس الأداء
-- =============================================
CREATE INDEX IF NOT EXISTS idx_students_score_desc ON students(score DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_students_level_gender ON students(level, gender);
CREATE INDEX IF NOT EXISTS idx_students_ceremony_code ON students(ceremony_code) WHERE ceremony_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_students_exam_date_hour ON students(exam_date, exam_hour);
CREATE INDEX IF NOT EXISTS idx_students_national_id ON students(national_id);
CREATE INDEX IF NOT EXISTS idx_students_student_code ON students(student_code);
CREATE INDEX IF NOT EXISTS idx_levels_active ON competition_levels(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_levels_title ON competition_levels(title);

-- =============================================
-- 4. قيود تكامل جدول competition_levels
-- =============================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'levels_age_range_valid') THEN
        ALTER TABLE competition_levels ADD CONSTRAINT levels_age_range_valid
            CHECK (max_age IS NULL OR min_age IS NULL OR max_age >= min_age);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'levels_max_capacity_non_negative') THEN
        ALTER TABLE competition_levels ADD CONSTRAINT levels_max_capacity_non_negative
            CHECK (max_capacity IS NULL OR max_capacity >= 0);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'levels_level_code_format') THEN
        ALTER TABLE competition_levels ADD CONSTRAINT levels_level_code_format
            CHECK (level_code IS NULL OR level_code ~ '^[A-Z]$');
    END IF;
END $$;

-- =============================================
-- 5. is_admin() - أصبح STABLE لتحسين الأداء
-- =============================================
CREATE OR REPLACE FUNCTION is_admin() 
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admins WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- =============================================
-- 6. assign_exam_slot() - advisory lock بدل LOCK TABLE + FIFO بدل LIFO
-- =============================================
CREATE OR REPLACE FUNCTION assign_exam_slot()
RETURNS TRIGGER AS $$
DECLARE
    schedule_json JSONB;
    slot JSONB;
    v_date DATE;
    v_start_hour INT;
    v_end_hour INT;
    v_students_per_hour INT;
    v_current_hour INT;
    assigned BOOLEAN := FALSE;
    slot_count INT;
    v_exam_period_start DATE;
    v_exam_period_end DATE;
BEGIN
    PERFORM pg_advisory_xact_lock(987654321);
    
    SELECT exam_schedule, exam_period_start, exam_period_end 
    INTO schedule_json, v_exam_period_start, v_exam_period_end 
    FROM app_settings WHERE id = 1 LIMIT 1;
    
    IF schedule_json IS NULL OR jsonb_array_length(schedule_json) = 0 THEN
        NEW.notes := COALESCE(NEW.notes || E'\n', '') || 'تنبيه: لم يتم تحديد ميعاد (لا يوجد جدول)';
        RETURN NEW;
    END IF;

    -- FIFO: ملء المواعيد الأقدم أولاً
    FOR slot IN 
        SELECT value FROM jsonb_array_elements(schedule_json)
        ORDER BY (value->>'date')::DATE ASC, (value->>'start_hour')::INT ASC
    LOOP
        v_date := (slot->>'date')::DATE;
        v_start_hour := (slot->>'start_hour')::INT;
        v_end_hour := (slot->>'end_hour')::INT;
        v_students_per_hour := (slot->>'students_per_hour')::INT;

        v_current_hour := v_end_hour - 1;
        WHILE v_current_hour >= v_start_hour LOOP
            SELECT COUNT(*) INTO slot_count FROM students WHERE exam_date = v_date AND exam_hour = v_current_hour;
            IF slot_count < v_students_per_hour THEN
                NEW.exam_date := v_date;
                NEW.exam_hour := v_current_hour;
                assigned := TRUE;
                EXIT;
            END IF;
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

DROP TRIGGER IF EXISTS trigger_assign_exam_slot ON students;
CREATE TRIGGER trigger_assign_exam_slot
    BEFORE INSERT ON students
    FOR EACH ROW
    EXECUTE FUNCTION assign_exam_slot();

-- =============================================
-- 7. generate_student_code() - LEFT JOIN بدل NOT EXISTS
-- =============================================
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

DROP TRIGGER IF EXISTS trg_generate_student_code ON students;
CREATE TRIGGER trg_generate_student_code
    BEFORE INSERT ON students
    FOR EACH ROW
    WHEN (NEW.student_code IS NULL)
    EXECUTE FUNCTION generate_student_code();

-- =============================================
-- 8. regenerate_student_code_on_level_change() - LEFT JOIN + advisory lock
-- =============================================
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

DROP TRIGGER IF EXISTS trg_regenerate_student_code_on_level_change ON students;
CREATE TRIGGER trg_regenerate_student_code_on_level_change
    BEFORE UPDATE ON students
    FOR EACH ROW
    WHEN (NEW.level IS DISTINCT FROM OLD.level OR NEW.gender IS DISTINCT FROM OLD.gender)
    EXECUTE FUNCTION regenerate_student_code_on_level_change();

-- =============================================
-- 9. query_ceremony_attendance - مصادقة ثنائية (رقم قومي + هاتف) + إصلاح نوع student_id
-- =============================================
CREATE OR REPLACE FUNCTION query_ceremony_attendance(p_national_id TEXT, p_phone TEXT)
RETURNS TABLE (
    student_id INTEGER,
    student_name TEXT,
    student_level TEXT,
    student_image TEXT,
    ceremony_code TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_open BOOLEAN;
BEGIN
    SELECT is_ceremony_query_open INTO v_is_open FROM app_settings WHERE id = 1;
    
    IF v_is_open IS NOT TRUE THEN
        RAISE EXCEPTION 'الاستعلام عن حضور الحفل غير متاح حالياً.';
    END IF;

    RETURN QUERY
    SELECT 
        s.id AS student_id,
        s.name AS student_name,
        s.level AS student_level,
        s.profile_image_url AS student_image,
        s.ceremony_code AS ceremony_code
    FROM students s
    WHERE s.national_id = p_national_id 
      AND s.phone = p_phone
      AND s.ceremony_code IS NOT NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION query_ceremony_attendance(TEXT, TEXT) TO anon, authenticated;

-- =============================================
-- 10. generate_all_ceremony_codes - منع التنفيذ المتزامن + معالجة NULL
-- =============================================
CREATE OR REPLACE FUNCTION generate_all_ceremony_codes()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF pg_try_advisory_xact_lock(987654324) = FALSE THEN
        RAISE EXCEPTION 'عملية توليد الأكواد جارية بالفعل، يرجى المحاولة لاحقاً.';
    END IF;

    UPDATE students SET ceremony_code = NULL;

    WITH honored_students AS (
        SELECT 
            s.id,
            s.gender,
            s.age,
            COALESCE(ASCII(c.level_code) - 64, 24) AS level_num,
            (
                COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0)
            ) AS total_score,
            DENSE_RANK() OVER (PARTITION BY s.level ORDER BY (
                COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0)
            ) DESC) as level_rank,
            ROW_NUMBER() OVER (ORDER BY COALESCE(ASCII(c.level_code), 88) ASC, (
                COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0)
            ) DESC, s.name ASC) as global_seq
        FROM students s
        JOIN competition_levels c ON c.title = s.level
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

-- =============================================
-- 11. Auto-update trigger لـ app_settings.updated_at
-- =============================================
CREATE OR REPLACE FUNCTION update_app_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_app_settings_updated_at ON app_settings;
CREATE TRIGGER trg_app_settings_updated_at
    BEFORE UPDATE ON app_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_app_settings_updated_at();

-- =============================================
-- 12. إضافة أعمدة إذا لم تكن موجودة
-- =============================================
ALTER TABLE app_settings ADD COLUMN IF NOT EXISTS is_ceremony_query_open BOOLEAN DEFAULT false;
ALTER TABLE students ADD COLUMN IF NOT EXISTS ceremony_code TEXT;

COMMIT;
