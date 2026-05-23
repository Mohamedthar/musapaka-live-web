-- =============================================
-- Migration: إعادة توليد كود الطالب عند تغيير المستوى أو النوع
-- عند تغيير المستوى: الكود القديم يتحرر للطالب الجديد القادم،
-- والطالب المحوّل يحصل على كود جديد من المستوى الجديد.
-- =============================================

CREATE OR REPLACE FUNCTION regenerate_student_code_on_level_change()
RETURNS TRIGGER AS $$
DECLARE
    v_level_code  CHAR(1);
    v_gender_num  CHAR(1);
    v_seq         INTEGER;
    v_prefix      TEXT;
BEGIN
    -- Lock to prevent race conditions under concurrent updates
    LOCK TABLE students IN SHARE ROW EXCLUSIVE MODE;

    -- Get the level_code letter for the new level (e.g. 'A', 'B', ...)
    SELECT level_code INTO v_level_code
    FROM competition_levels
    WHERE title = NEW.level
    LIMIT 1;

    IF v_level_code IS NULL THEN
        v_level_code := 'X';
    END IF;

    -- Encode gender as a digit
    v_gender_num := CASE
        WHEN NEW.gender = 'ذكر'  THEN '1'
        WHEN NEW.gender = 'أنثى' THEN '0'
        ELSE '9'
    END;

    v_prefix := v_level_code || v_gender_num;

    -- Find the next available sequence for this prefix, excluding the current student
    SELECT COALESCE(MAX(CAST(SUBSTRING(student_code FROM 3) AS INTEGER)), 0) + 1
    INTO v_seq
    FROM students
    WHERE student_code LIKE v_prefix || '%'
      AND id != OLD.id;

    -- Assign new code: e.g. B1003
    NEW.student_code := v_prefix || LPAD(v_seq::TEXT, 3, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop if exists then recreate
DROP TRIGGER IF EXISTS trg_regenerate_student_code_on_level_change ON students;

CREATE TRIGGER trg_regenerate_student_code_on_level_change
    BEFORE UPDATE ON students
    FOR EACH ROW
    WHEN (NEW.level IS DISTINCT FROM OLD.level OR NEW.gender IS DISTINCT FROM OLD.gender)
    EXECUTE FUNCTION regenerate_student_code_on_level_change();
