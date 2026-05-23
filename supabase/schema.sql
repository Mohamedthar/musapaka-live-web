-- =============================================
-- Quran Contest Management - Database Setup (Safe Migration Version)
-- This script is safe to run multiple times without losing data.
-- =============================================

-- 1. Create students table if not exists
CREATE TABLE IF NOT EXISTS students (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL,
    phone TEXT NOT NULL,
    level TEXT NOT NULL,
    score DOUBLE PRECISION,
    national_id TEXT,
    gender TEXT,
    memorizer_name TEXT,
    memorizer_phone TEXT,
    memorizer_address TEXT,
    location TEXT,
    profile_image_url TEXT,
    birth_certificate_url TEXT,
    registration_ip TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure all columns exist for students (Migration support)
ALTER TABLE students ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE students ADD COLUMN IF NOT EXISTS score DOUBLE PRECISION;
ALTER TABLE students ADD COLUMN IF NOT EXISTS national_id TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS memorizer_name TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS birth_certificate_url TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE students ADD COLUMN IF NOT EXISTS memorizer_phone TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS memorizer_address TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS selected_rewaya TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS rewaya_score DOUBLE PRECISION;
ALTER TABLE students ADD COLUMN IF NOT EXISTS tajweed_score DOUBLE PRECISION;
ALTER TABLE students ADD COLUMN IF NOT EXISTS voice_score DOUBLE PRECISION;
ALTER TABLE students ADD COLUMN IF NOT EXISTS meaning_score DOUBLE PRECISION;
ALTER TABLE students ADD COLUMN IF NOT EXISTS registration_ip TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS branch_name TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS memorization_amount INTEGER DEFAULT 0;
-- 2. Add/Update constraints safely
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'national_id_format') THEN
        ALTER TABLE students ADD CONSTRAINT national_id_format CHECK (national_id IS NULL OR national_id ~ '^\d{14}$');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_phone_unique') THEN
        ALTER TABLE students ADD CONSTRAINT students_phone_unique UNIQUE (phone);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_national_id_unique') THEN
        ALTER TABLE students ADD CONSTRAINT students_national_id_unique UNIQUE (national_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_name_unique') THEN
        ALTER TABLE students ADD CONSTRAINT students_name_unique UNIQUE (name);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_age_check') THEN
        ALTER TABLE students ADD CONSTRAINT students_age_check CHECK (age BETWEEN 5 AND 100);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_name_not_empty') THEN
        ALTER TABLE students ADD CONSTRAINT students_name_not_empty CHECK (name <> '');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_phone_not_empty') THEN
        ALTER TABLE students ADD CONSTRAINT students_phone_not_empty CHECK (phone <> '');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_score_check') THEN
        ALTER TABLE students ADD CONSTRAINT students_score_check CHECK (score IS NULL OR (score >= 0 AND score <= 1000));
    END IF;
END $$;

-- 3. Enable RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- 4. Helper functions (Replaceable)
CREATE OR REPLACE FUNCTION is_admin() 
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admins WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Policies (Drop and Recreate to ensure they match latest logic)
-- Public insert removed for security; registration goes through the API (service_role_key).
-- Only authenticated admins can insert/select/update/delete directly (via the Flutter app).
DROP POLICY IF EXISTS "Allow public insert" ON students;

DROP POLICY IF EXISTS "Allow admin insert" ON students;
CREATE POLICY "Allow admin insert" ON students FOR INSERT WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Allow admin select" ON students;
CREATE POLICY "Allow admin select" ON students FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Allow admin update" ON students;
CREATE POLICY "Allow admin update" ON students FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Allow admin delete" ON students;
CREATE POLICY "Allow admin delete" ON students FOR DELETE USING (is_admin());

-- 6. Indexes (Safe)
CREATE INDEX IF NOT EXISTS idx_students_level ON students(level);
CREATE INDEX IF NOT EXISTS idx_students_created_at ON students(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_students_phone ON students(phone);
CREATE INDEX IF NOT EXISTS idx_students_national_id ON students(national_id);
CREATE INDEX IF NOT EXISTS idx_students_name ON students(name);
CREATE INDEX IF NOT EXISTS idx_students_registration_ip ON students(registration_ip);

-- 7. Functions & Triggers
DROP FUNCTION IF EXISTS get_student_stats();
CREATE FUNCTION get_student_stats()
RETURNS TABLE (
    total_students BIGINT,
    avg_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_students,
        AVG(score) FILTER (WHERE score IS NOT NULL) as avg_score
    FROM students;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_student_status(p_national_id TEXT, p_student_code TEXT)
RETURNS jsonb AS $$
DECLARE
  res jsonb;
BEGIN
  SELECT jsonb_build_object(
    'name', s.name,
    'level', s.level,
    'level_content', c.content,
    'score', s.score,
    'rewaya_score', s.rewaya_score,
    'tajweed_score', s.tajweed_score,
    'voice_score', s.voice_score,
    'meaning_score', s.meaning_score,
    'created_at', s.created_at,
    'student_code', s.student_code,
    'location', s.location,
    'age', s.age,
    'gender', s.gender,
    'birth_date', s.birth_date,
    'profile_image_url', s.profile_image_url,
    'exam_date', s.exam_date,
    'exam_hour', s.exam_hour
  ) INTO res
  FROM students s
  LEFT JOIN competition_levels c ON c.title = s.level
  WHERE s.national_id = p_national_id AND s.student_code = p_student_code
  LIMIT 1;
  
  RETURN res;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION get_student_status TO anon, authenticated;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_students_updated_at ON students;
CREATE TRIGGER update_students_updated_at
    BEFORE UPDATE ON students
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 8. Admins table
CREATE TABLE IF NOT EXISTS admins (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'admins_id_fkey') THEN
        ALTER TABLE admins ADD CONSTRAINT admins_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert to admins" ON admins;
CREATE POLICY "Allow admin insert to admins" ON admins FOR INSERT WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Allow admin select from admins" ON admins;
CREATE POLICY "Allow admin select from admins" ON admins FOR SELECT USING (is_admin());

-- 9. Competition Levels table
CREATE TABLE IF NOT EXISTS competition_levels (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    notes TEXT,
    min_age INTEGER,
    max_age INTEGER,
    max_capacity INTEGER,
    branches TEXT[] DEFAULT '{}',
    require_custom_amount BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Migration for new columns in competition_levels
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS total_points INTEGER DEFAULT 100;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS has_rewaya BOOLEAN DEFAULT FALSE;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS rewaya_max_score INTEGER DEFAULT 100;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS available_rewayas JSONB DEFAULT '[]'::jsonb;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS has_tajweed BOOLEAN DEFAULT FALSE;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS tajweed_max_score INTEGER DEFAULT 100;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS has_voice BOOLEAN DEFAULT FALSE;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS voice_max_score INTEGER DEFAULT 100;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS has_meaning BOOLEAN DEFAULT FALSE;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS meaning_max_score INTEGER DEFAULT 100;

-- Prizes
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS first_prize TEXT;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS second_prize TEXT;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS third_prize TEXT;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'competition_levels_title_unique') THEN
        ALTER TABLE competition_levels ADD CONSTRAINT competition_levels_title_unique UNIQUE (title);
    END IF;
END $$;

ALTER TABLE competition_levels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public select from levels" ON competition_levels;
CREATE POLICY "Allow public select from levels" ON competition_levels FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow admin manage levels" ON competition_levels;
CREATE POLICY "Allow admin manage levels" ON competition_levels FOR ALL USING (is_admin());

-- 10. Sample Data (Only inserts if not exists)
INSERT INTO competition_levels (title, content, notes, min_age, max_age, max_capacity) 
SELECT 'المستوى الأول', 'القرآن الكريم كاملاً مع التجويد', 'للجميع', NULL, NULL, NULL
WHERE NOT EXISTS (SELECT 1 FROM competition_levels WHERE title = 'المستوى الأول');

INSERT INTO competition_levels (title, content, notes, min_age, max_age, max_capacity) 
SELECT 'المستوى الثاني', 'نصف القرآن الكريم', 'فوق 18 عاماً', 18, NULL, NULL
WHERE NOT EXISTS (SELECT 1 FROM competition_levels WHERE title = 'المستوى الثاني');

-- =========================================================
-- 11. App Settings Table
-- =========================================================
CREATE TABLE IF NOT EXISTS app_settings (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL DEFAULT 'مسابقة القرآن الكريم',
    description TEXT NOT NULL DEFAULT 'أكبر مسابقة قرآنية محلية تهدف إلى تشجيع الأجيال على حفظ كتاب الله وتجويده.',
    total_prizes TEXT NOT NULL DEFAULT '50,000+',
    committees_count INTEGER NOT NULL DEFAULT 3,
    
    -- Registration Control
    is_registration_open BOOLEAN NOT NULL DEFAULT true,
    registration_start_date DATE,
    registration_end_date DATE,
    
    -- Result Query Control
    is_result_query_open BOOLEAN NOT NULL DEFAULT false,
    
    -- Exam Scheduling
    exam_period_start DATE,
    exam_period_end DATE,
    exam_schedule JSONB NOT NULL DEFAULT '[]'::jsonb,
    
    -- UI Information
    timeline JSONB NOT NULL DEFAULT '[
      {"title": "فتح باب التسجيل", "date": "1 رمضان 1446", "desc": "بدء استقبال طلبات التسجيل عبر البوابة الإلكترونية وتحديد المستويات."},
      {"title": "إغلاق التسجيل ومراجعة الطلبات", "date": "15 رمضان 1446", "desc": "إغلاق البوابة ومراجعة البيانات والمستندات لتحديد لجان الاختبار المبدئية."},
      {"title": "الاختبارات التمهيدية والنهائية", "date": "20 رمضان 1446", "desc": "انعقاد لجان الاستماع والاختبار للمتسابقين المقبولين بمقر المسابقة."},
      {"title": "إعلان النتائج والحفل الختامي", "date": "27 رمضان 1446", "desc": "تكريم الفائزين في حفل قرآني مهيب وتوزيع الجوائز والشهادات."}
    ]'::jsonb,
    
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure only one row exists
INSERT INTO app_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- RLS
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public select from settings" ON app_settings;
CREATE POLICY "Allow public select from settings" ON app_settings FOR SELECT USING (true);

DROP POLICY IF EXISTS "admins_update_app_settings" ON app_settings;
CREATE POLICY "admins_update_app_settings" ON app_settings
    FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

GRANT SELECT ON TABLE public.app_settings TO anon, authenticated;

-- =========================================================
-- 12. نظام الجدولة والأكواد التلقائية (Automation & Logic)
-- =========================================================

-- إضافة أعمدة التحكم إذا لم تكن موجودة
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS level_code CHAR(1);
ALTER TABLE students ADD COLUMN IF NOT EXISTS student_code TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS exam_date DATE;
ALTER TABLE students ADD COLUMN IF NOT EXISTS exam_hour INTEGER;
ALTER TABLE students ADD COLUMN IF NOT EXISTS notes TEXT;

-- إنشاء الفهارس لضمان السرعة ومنع التكرار
CREATE UNIQUE INDEX IF NOT EXISTS idx_levels_code ON competition_levels(level_code);
CREATE UNIQUE INDEX IF NOT EXISTS idx_students_student_code ON students(student_code);
CREATE INDEX IF NOT EXISTS idx_students_exam_schedule ON students(exam_date, exam_hour);

-- قيد فحص هيكل الجدول
ALTER TABLE app_settings DROP CONSTRAINT IF EXISTS exam_schedule_structure_check;
ALTER TABLE app_settings ADD CONSTRAINT exam_schedule_structure_check CHECK (
    exam_schedule IS NULL OR jsonb_typeof(exam_schedule) = 'array'
);

-- 12.1 نظام توليد أكواد المستويات (A, B, C...)
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
        RAISE EXCEPTION 'وصلت للحد الأقصى للمستويات (26 مستوى)'; 
    END IF;
    
    NEW.level_code := CHR(v_code_ascii);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_assign_level_code ON competition_levels;
CREATE TRIGGER trg_assign_level_code
    BEFORE INSERT ON competition_levels
    FOR EACH ROW
    WHEN (NEW.level_code IS NULL)
    EXECUTE FUNCTION assign_level_code();

-- 12.2 نظام تعيين مواعيد الاختبارات (LIFO Scheduling)
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
    -- Lock students table to prevent deadlocks and race conditions under high concurrency
    LOCK TABLE students IN SHARE ROW EXCLUSIVE MODE;
    
    SELECT exam_schedule, exam_period_start, exam_period_end 
    INTO schedule_json, v_exam_period_start, v_exam_period_end 
    FROM app_settings WHERE id = 1 LIMIT 1;
    
    IF schedule_json IS NULL OR jsonb_array_length(schedule_json) = 0 THEN
        NEW.notes := COALESCE(NEW.notes || E'\n', '') || 'تنبيه: لم يتم تحديد ميعاد (لا يوجد جدول)';
        RETURN NEW;
    END IF;

    -- البحث من المواعيد الأحدث للأقدم (LIFO)
    FOR slot IN 
        SELECT value FROM jsonb_array_elements(schedule_json)
        ORDER BY (value->>'date')::DATE DESC, (value->>'end_hour')::INT DESC
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

-- 12.3 نظام توليد أكواد الطلاب (A1001)
CREATE OR REPLACE FUNCTION generate_student_code()
RETURNS TRIGGER AS $$
DECLARE
    v_level_code  CHAR(1);
    v_gender_num  CHAR(1);
    v_seq         INTEGER;
    v_prefix      TEXT;
BEGIN
    -- Lock students table to prevent deadlocks and race conditions under high concurrency
    LOCK TABLE students IN SHARE ROW EXCLUSIVE MODE;

    SELECT level_code INTO v_level_code FROM competition_levels WHERE title = NEW.level LIMIT 1;
    IF v_level_code IS NULL THEN v_level_code := 'X'; END IF;

    v_gender_num := CASE WHEN NEW.gender = 'ذكر' THEN '1' WHEN NEW.gender = 'أنثى' THEN '0' ELSE '9' END;
    v_prefix := v_level_code || v_gender_num;

    -- Find the smallest missing sequence number (gap filling)
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

DROP TRIGGER IF EXISTS trg_generate_student_code ON students;
CREATE TRIGGER trg_generate_student_code
    BEFORE INSERT ON students
    FOR EACH ROW
    WHEN (NEW.student_code IS NULL)
    EXECUTE FUNCTION generate_student_code();

-- 12.4 نظام التحقق من سعة المستوى (Max Capacity Check)
CREATE OR REPLACE FUNCTION check_level_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_capacity INTEGER;
    v_current INTEGER;
BEGIN
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

DROP TRIGGER IF EXISTS trg_check_level_capacity ON students;
CREATE TRIGGER trg_check_level_capacity
    BEFORE INSERT ON students
    FOR EACH ROW
    EXECUTE FUNCTION check_level_capacity();

-- 12.5 نظام الإحصائيات المتقدم المحدث (Advanced get_student_stats)
CREATE OR REPLACE FUNCTION get_student_stats(
    p_level TEXT DEFAULT NULL,
    p_gender TEXT DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    total_students BIGINT,
    avg_score NUMERIC,
    male_count BIGINT,
    female_count BIGINT,
    highest_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT,
        COALESCE(AVG(score), 0)::NUMERIC,
        COUNT(CASE WHEN gender = 'ذكر' THEN 1 END)::BIGINT,
        COUNT(CASE WHEN gender = 'أنثى' THEN 1 END)::BIGINT,
        COALESCE(MAX(score), 0)::NUMERIC
    FROM students
    WHERE 
        (p_level IS NULL OR level = p_level) AND
        (p_gender IS NULL OR gender = p_gender) AND
        (p_start_date IS NULL OR created_at::DATE >= p_start_date) AND
        (p_end_date IS NULL OR created_at::DATE <= p_end_date);
END;
$$ LANGUAGE plpgsql;

-- 12.6 Cascade Delete students when a competition level is deleted
CREATE OR REPLACE FUNCTION cascade_delete_level_students()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM students WHERE level = OLD.title;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cascade_delete_level ON competition_levels;
CREATE TRIGGER trg_cascade_delete_level
    BEFORE DELETE ON competition_levels
    FOR EACH ROW
    EXECUTE FUNCTION cascade_delete_level_students();

-- 12.6b إعادة توليد كود الطالب عند تغيير المستوى أو النوع
-- عند تغيير المستوى: الكود القديم يصبح متاحاً لأول طالب يسجل بعده،
-- والطالب يحصل على كود جديد من المستوى الجديد (آخر رقم تسلسلي).
CREATE OR REPLACE FUNCTION regenerate_student_code_on_level_change()
RETURNS TRIGGER AS $$
DECLARE
    v_level_code  CHAR(1);
    v_gender_num  CHAR(1);
    v_seq         INTEGER;
    v_prefix      TEXT;
BEGIN
    -- Lock to prevent race conditions
    LOCK TABLE students IN SHARE ROW EXCLUSIVE MODE;

    SELECT level_code INTO v_level_code FROM competition_levels WHERE title = NEW.level LIMIT 1;
    IF v_level_code IS NULL THEN v_level_code := 'X'; END IF;

    v_gender_num := CASE WHEN NEW.gender = 'ذكر' THEN '1' WHEN NEW.gender = 'أنثى' THEN '0' ELSE '9' END;
    v_prefix := v_level_code || v_gender_num;

    -- Find the smallest missing sequence number (gap filling), excluding current student
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

DROP TRIGGER IF EXISTS trg_regenerate_student_code_on_level_change ON students;
CREATE TRIGGER trg_regenerate_student_code_on_level_change
    BEFORE UPDATE ON students
    FOR EACH ROW
    WHEN (NEW.level IS DISTINCT FROM OLD.level OR NEW.gender IS DISTINCT FROM OLD.gender)
    EXECUTE FUNCTION regenerate_student_code_on_level_change();

-- 12.7 Secure function to retrieve a lost student_code
CREATE OR REPLACE FUNCTION retrieve_student_code(p_national_id TEXT, p_phone TEXT)
RETURNS TABLE (
    student_code TEXT,
    name TEXT
) SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT s.student_code::TEXT, s.name::TEXT
    FROM students s
    WHERE s.national_id = p_national_id AND s.phone = p_phone;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION retrieve_student_code(TEXT, TEXT) TO anon, authenticated;
