-- =============================================
-- Migration: Ceremony Attendance Query & Codes
-- =============================================

-- 1. إضافة عمود is_ceremony_query_open إلى جدول app_settings
ALTER TABLE app_settings ADD COLUMN IF NOT EXISTS is_ceremony_query_open BOOLEAN DEFAULT false;

-- 2. إضافة عمود ceremony_code إلى جدول students
ALTER TABLE students ADD COLUMN IF NOT EXISTS ceremony_code TEXT;

-- 3. دالة الاستعلام عن حضور الحفل للواجهة الأمامية (تحتاج رقم قومي + رقم هاتف)
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

-- 4. دالة توليد الأكواد وتحديث جدول الطلاب
CREATE OR REPLACE FUNCTION generate_all_ceremony_codes()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- منع التنفيذ المتزامن باستخدام advisory lock
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
            DENSE_RANK() OVER (PARTITION BY s.level ORDER BY s.score DESC) as level_rank,
            ROW_NUMBER() OVER (ORDER BY COALESCE(ASCII(c.level_code), 88) ASC, s.score DESC, s.name ASC) as global_seq
        FROM students s
        JOIN competition_levels c ON c.title = s.level
        WHERE s.score IS NOT NULL AND c.total_points > 0 
          AND ((s.score::NUMERIC / c.total_points::NUMERIC) * 100) >= 95
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
