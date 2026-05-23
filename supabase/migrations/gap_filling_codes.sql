-- =============================================
-- Migration: نظام سد الفجوات في الأكواد (Gap Filling)
-- لضمان أن الطالب الجديد يأخذ أصغر كود متاح تم تحريره مسبقاً.
-- =============================================

-- 1. تحديث دالة التوليد الأساسية (عند الإضافة)
CREATE OR REPLACE FUNCTION generate_student_code()
RETURNS TRIGGER AS $$
DECLARE
    v_level_code  CHAR(1);
    v_gender_num  CHAR(1);
    v_seq         INTEGER;
    v_prefix      TEXT;
BEGIN
    -- قفل الجدول لمنع التضارب
    LOCK TABLE students IN SHARE ROW EXCLUSIVE MODE;

    SELECT level_code INTO v_level_code FROM competition_levels WHERE title = NEW.level LIMIT 1;
    IF v_level_code IS NULL THEN v_level_code := 'X'; END IF;

    v_gender_num := CASE WHEN NEW.gender = 'ذكر' THEN '1' WHEN NEW.gender = 'أنثى' THEN '0' ELSE '9' END;
    v_prefix := v_level_code || v_gender_num;

    -- البحث عن أصغر رقم تسلسلي غير مستخدم (لسد الفراغات)
    SELECT s.seq INTO v_seq
    FROM generate_series(1, 9999) AS s(seq)
    WHERE NOT EXISTS (
        SELECT 1 FROM students 
        WHERE student_code = v_prefix || LPAD(s.seq::TEXT, 3, '0')
    )
    ORDER BY s.seq ASC
    LIMIT 1;

    NEW.student_code := v_prefix || LPAD(v_seq::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. تحديث دالة توليد الكود عند التعديل (عند تغيير المستوى)
CREATE OR REPLACE FUNCTION regenerate_student_code_on_level_change()
RETURNS TRIGGER AS $$
DECLARE
    v_level_code  CHAR(1);
    v_gender_num  CHAR(1);
    v_seq         INTEGER;
    v_prefix      TEXT;
BEGIN
    LOCK TABLE students IN SHARE ROW EXCLUSIVE MODE;

    SELECT level_code INTO v_level_code FROM competition_levels WHERE title = NEW.level LIMIT 1;
    IF v_level_code IS NULL THEN v_level_code := 'X'; END IF;

    v_gender_num := CASE WHEN NEW.gender = 'ذكر' THEN '1' WHEN NEW.gender = 'أنثى' THEN '0' ELSE '9' END;
    v_prefix := v_level_code || v_gender_num;

    -- البحث عن أصغر رقم تسلسلي غير مستخدم (لسد الفراغات) مع استثناء الطالب الحالي
    SELECT s.seq INTO v_seq
    FROM generate_series(1, 9999) AS s(seq)
    WHERE NOT EXISTS (
        SELECT 1 FROM students 
        WHERE student_code = v_prefix || LPAD(s.seq::TEXT, 3, '0')
          AND id != OLD.id
    )
    ORDER BY s.seq ASC
    LIMIT 1;

    NEW.student_code := v_prefix || LPAD(v_seq::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
