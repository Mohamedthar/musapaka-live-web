-- =============================================
-- Migration: Add level_id FK to students (Safe, Non-Breaking)
-- الهدف: ربط الطلاب بالمستوى عبر id بدلاً من title (نص)
-- مع الحفاظ على حقل level TEXT للتطبيق الحالي (للتوافق)
-- =============================================
BEGIN;

-- 1. إضافة عمود level_id إذا لم يكن موجوداً
ALTER TABLE students ADD COLUMN IF NOT EXISTS level_id INTEGER;

-- 2. ملء level_id من القيم الموجودة (باستخدام title الموجود)
UPDATE students s
SET level_id = cl.id
FROM competition_levels cl
WHERE s.level = cl.title
  AND s.level_id IS NULL;

-- 3. إنشاء دالة لتحديث level_id تلقائياً عند الإدراج أو التحديث
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

-- 4. تفعيل trigger لضمان تزامن level_id دائماً
DROP TRIGGER IF EXISTS trg_sync_level_id ON students;
CREATE TRIGGER trg_sync_level_id
    BEFORE INSERT OR UPDATE OF level ON students
    FOR EACH ROW
    EXECUTE FUNCTION sync_level_id();

-- 5. إضافة قيد المفتاح الأجنبي (إذا لم يكن موجوداً)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_students_level_id') THEN
        ALTER TABLE students ADD CONSTRAINT fk_students_level_id
            FOREIGN KEY (level_id) REFERENCES competition_levels(id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- 6. إضافة فهرس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_students_level_id ON students(level_id);

-- 7. تحديث triggers/functions الداخلية لتستخدم level_id للبحث (أسرع)
-- بدلاً من WHERE level = '...' نستخدم WHERE level_id = ...

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

-- 8. دالة assign_exam_slot تبقى كما هي (تستخدم level فقط لكود المستوى)

-- 9. تحديث دالة generate_all_ceremony_codes لاستخدام JOIN على level_id
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

-- 10. إضافة NOT NULL على level_id بعد التأكد من امتلاء جميع الصفوف
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count FROM students WHERE level_id IS NULL;
    IF null_count = 0 THEN
        ALTER TABLE students ALTER COLUMN level_id SET NOT NULL;
    END IF;
END $$;

COMMIT;
