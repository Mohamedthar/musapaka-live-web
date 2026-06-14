-- =================================================================================================
-- مسابقة القرآن الكريم — Database Schema
-- =================================================================================================
-- يحتوي هذا الملف على كامل هيكل قاعدة البيانات:
--   • الجداول + البيانات الابتدائية
--   • القيود (CHECK, UNIQUE, FK, NOT NULL)
--   • الفهارس (عادية, مركبة, جزئية)
--   • أمان الصفوف (RLS Policies)
--      • المحفزات (Triggers) + الدوال المساعدة (Helper Functions)
--   • الدوال الداخلية (Internal Functions)
--   • دوال الـ API العامة (Public API)
--   • دوال الحفل (Ceremony)
--
-- الملف آمن للتشغيل المتكرر (Idempotent): جميع الأوامر تستخدم IF NOT EXISTS / CREATE OR REPLACE.
-- =================================================================================================


-- =================================================================================================
-- القسم الأول: الجداول — Tables
-- =================================================================================================

-- -------------------------------------------------------------------
-- 1.1 المشتركون — Students
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
    id                  SERIAL PRIMARY KEY,
    name                TEXT NOT NULL,
    age                 INTEGER NOT NULL,
    phone               TEXT NOT NULL,
    national_id         TEXT,
    gender              TEXT,
    level               TEXT NOT NULL,
    level_id            INTEGER,
    score               DOUBLE PRECISION,
    rewaya_score        DOUBLE PRECISION,
    tajweed_score       DOUBLE PRECISION,
    voice_score         DOUBLE PRECISION,
    meaning_score       DOUBLE PRECISION,
    memorizer_name      TEXT,
    memorizer_phone     TEXT,
    memorizer_address   TEXT,
    location            TEXT,
    profile_image_url   TEXT,
    birth_certificate_url TEXT,
    birth_date          DATE,
    selected_rewaya     TEXT,
    branch_name         TEXT,
    memorization_amount INTEGER DEFAULT 0,
    registration_ip     TEXT,
    student_code        TEXT,
    ceremony_code       TEXT,
    exam_date           DATE,
    exam_hour           INTEGER,
    is_waitlisted       BOOLEAN DEFAULT false,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -------------------------------------------------------------------
-- 1.2 المدراء — Admins
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admins (
    id         UUID PRIMARY KEY,
    name       TEXT NOT NULL,
    phone      TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'admins_id_fkey') THEN
        ALTER TABLE admins ADD CONSTRAINT admins_id_fkey
            FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- -------------------------------------------------------------------
-- 1.3 مستويات المسابقة — Competition Levels
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS competition_levels (
    id                   SERIAL PRIMARY KEY,
    title                TEXT NOT NULL,
    content              TEXT NOT NULL,
    notes                TEXT,
    min_age              INTEGER,
    max_age              INTEGER,
    max_capacity         INTEGER,
    branches             TEXT[] DEFAULT '{}',
    require_custom_amount BOOLEAN DEFAULT false,
    is_active            BOOLEAN DEFAULT TRUE,
    total_points         INTEGER DEFAULT 100,
    has_rewaya           BOOLEAN DEFAULT FALSE,
    rewaya_max_score     INTEGER DEFAULT 100,
    available_rewayas    JSONB DEFAULT '[]'::jsonb,
    has_tajweed          BOOLEAN DEFAULT FALSE,
    tajweed_max_score    INTEGER DEFAULT 100,
    has_voice            BOOLEAN DEFAULT FALSE,
    voice_max_score      INTEGER DEFAULT 100,
    has_meaning          BOOLEAN DEFAULT FALSE,
    meaning_max_score    INTEGER DEFAULT 100,
    max_score            INTEGER DEFAULT 100,
    passing_percentage   INTEGER DEFAULT 95,
    first_prize          TEXT,
    second_prize         TEXT,
    third_prize          TEXT,
    prizes               TEXT,
    level_code           CHAR(1),
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -------------------------------------------------------------------
-- 1.4 إعدادات التطبيق — App Settings
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_settings (
    id                       SERIAL PRIMARY KEY,
    title                    TEXT NOT NULL DEFAULT 'مسابقة القرآن الكريم',
    description              TEXT NOT NULL DEFAULT 'أكبر مسابقة قرآنية محلية تهدف إلى تشجيع الأجيال على حفظ كتاب الله وتجويده.',
    total_prizes             TEXT NOT NULL DEFAULT '50,000+',
    committees_count         INTEGER NOT NULL DEFAULT 3,
    is_registration_open     BOOLEAN NOT NULL DEFAULT true,
    registration_start_date  DATE,
    registration_end_date    DATE,
    is_result_query_open     BOOLEAN NOT NULL DEFAULT false,
    result_query_open_date   TIMESTAMPTZ,
    is_ceremony_query_open   BOOLEAN NOT NULL DEFAULT false,
    ceremony_query_open_date TIMESTAMPTZ,
    competition_title        TEXT,
    exam_period_start        DATE,
    exam_period_end          DATE,
    exam_schedule            JSONB NOT NULL DEFAULT '[]'::jsonb,
    timeline                 JSONB NOT NULL DEFAULT '[]'::jsonb,
    faqs                     JSONB NOT NULL DEFAULT '[]'::jsonb,
    updated_at               TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO app_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- -------------------------------------------------------------------
-- 1.5 بيانات البداية — Seed Data
-- -------------------------------------------------------------------
INSERT INTO competition_levels (title, content, notes, min_age, max_age, max_capacity)
SELECT 'المستوى الأول', 'القرآن الكريم كاملاً مع التجويد', 'للجميع', NULL, NULL, NULL
WHERE NOT EXISTS (SELECT 1 FROM competition_levels WHERE title = 'المستوى الأول');

INSERT INTO competition_levels (title, content, notes, min_age, max_age, max_capacity)
SELECT 'المستوى الثاني', 'نصف القرآن الكريم', 'فوق 18 عاماً', 18, NULL, NULL
WHERE NOT EXISTS (SELECT 1 FROM competition_levels WHERE title = 'المستوى الثاني');


-- =================================================================================================
-- القسم الثاني: قيود التكامل — Constraints
-- =================================================================================================

-- -------------------------------------------------------------------
-- 2.1 قيود جدول الطلاب
-- -------------------------------------------------------------------
DO $$
BEGIN
    -- students_phone_unique removed (migration 018) — siblings may share parent's phone
    ALTER TABLE students DROP CONSTRAINT IF EXISTS students_phone_unique;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_national_id_unique') THEN
        ALTER TABLE students ADD CONSTRAINT students_national_id_unique UNIQUE (national_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_name_unique') THEN
        ALTER TABLE students ADD CONSTRAINT students_name_unique UNIQUE (name);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'national_id_format') THEN
        ALTER TABLE students ADD CONSTRAINT national_id_format CHECK (national_id IS NULL OR national_id ~ '^\d{14}$');
    END IF;
    -- students_age_check removed (migration 015). Age is computed from birth_date.
    ALTER TABLE students DROP CONSTRAINT IF EXISTS students_age_check;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_name_not_empty') THEN
        ALTER TABLE students ADD CONSTRAINT students_name_not_empty CHECK (name <> '');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_phone_not_empty') THEN
        ALTER TABLE students ADD CONSTRAINT students_phone_not_empty CHECK (phone <> '');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_gender_check') THEN
        ALTER TABLE students ADD CONSTRAINT students_gender_check CHECK (gender IS NULL OR gender IN ('ذكر', 'أنثى'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_score_check') THEN
        ALTER TABLE students ADD CONSTRAINT students_score_check CHECK (score IS NULL OR (score >= 0 AND score <= 1000));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_memorization_non_negative') THEN
        ALTER TABLE students ADD CONSTRAINT students_memorization_non_negative CHECK (memorization_amount >= 0);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_memorizer_phone_format') THEN
        ALTER TABLE students ADD CONSTRAINT students_memorizer_phone_format CHECK (memorizer_phone IS NOT NULL AND memorizer_phone <> '' AND memorizer_phone ~ '^(010|011|012|015)[0-9]{8}$');
    END IF;
END $$;

-- -------------------------------------------------------------------
-- 2.2 المفاتيح الأجنبية
-- -------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_students_level_id') THEN
        ALTER TABLE students ADD CONSTRAINT fk_students_level_id
            FOREIGN KEY (level_id) REFERENCES competition_levels(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_students_level') THEN
        ALTER TABLE students ADD CONSTRAINT fk_students_level
            FOREIGN KEY (level) REFERENCES competition_levels(title) ON DELETE RESTRICT;
    END IF;
END $$;

-- -------------------------------------------------------------------
-- 2.3 memorizer_name NOT NULL (مع فحص أمان للبيانات القديمة)
-- -------------------------------------------------------------------
DO $$
DECLARE null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count FROM students WHERE memorizer_name IS NULL;
    IF null_count = 0 THEN
        ALTER TABLE students ALTER COLUMN memorizer_name SET NOT NULL;
    END IF;
END $$;

-- -------------------------------------------------------------------
-- 2.4 قيود جدول المستويات
-- -------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'competition_levels_title_unique') THEN
        ALTER TABLE competition_levels ADD CONSTRAINT competition_levels_title_unique UNIQUE (title);
    END IF;
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
    -- passing_percentage range check (1-100)
    ALTER TABLE competition_levels DROP CONSTRAINT IF EXISTS levels_passing_pct_range;
    ALTER TABLE competition_levels ADD CONSTRAINT levels_passing_pct_range
        CHECK (passing_percentage IS NULL OR (passing_percentage >= 1 AND passing_percentage <= 100));
END $$;

-- -------------------------------------------------------------------
-- 2.5 قيود app_settings — صف وحيد + تواريخ صحيحة
-- -------------------------------------------------------------------
ALTER TABLE app_settings DROP CONSTRAINT IF EXISTS exam_schedule_structure_check;
ALTER TABLE app_settings ADD CONSTRAINT exam_schedule_structure_check CHECK (
    exam_schedule IS NULL OR jsonb_typeof(exam_schedule) = 'array'
);

-- تأكد أن جدول الإعدادات لا يحتوي إلا على صف واحد (id = 1)
ALTER TABLE app_settings DROP CONSTRAINT IF EXISTS app_settings_single_row;
ALTER TABLE app_settings ADD CONSTRAINT app_settings_single_row CHECK (id = 1);

-- تأكد من ترتيب تواريخ التسجيل
ALTER TABLE app_settings DROP CONSTRAINT IF EXISTS app_settings_registration_dates;
ALTER TABLE app_settings ADD CONSTRAINT app_settings_registration_dates CHECK (
    registration_end_date IS NULL OR registration_start_date IS NULL OR registration_end_date >= registration_start_date
);


-- =================================================================================================
-- القسم الثالث: الفهارس — Indexes
-- =================================================================================================

-- -------------------------------------------------------------------
-- 3.1 فهارس الطلاب — أساسية
-- -------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_students_level              ON students(level);
CREATE INDEX IF NOT EXISTS idx_students_level_id           ON students(level_id);
CREATE INDEX IF NOT EXISTS idx_students_created_at         ON students(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_students_phone              ON students(phone);
CREATE INDEX IF NOT EXISTS idx_students_national_id        ON students(national_id);
CREATE INDEX IF NOT EXISTS idx_students_name               ON students(name);
CREATE INDEX IF NOT EXISTS idx_students_registration_ip    ON students(registration_ip);

-- -------------------------------------------------------------------
-- 3.2 فهارس الطلاب — أداء
-- -------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_students_score_desc         ON students(score DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_students_level_gender       ON students(level, gender);
CREATE INDEX IF NOT EXISTS idx_students_exam_date_hour     ON students(exam_date, exam_hour);

-- -------------------------------------------------------------------
-- 3.3 فهارس الطلاب — مركبة (Composite)
-- -------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_students_nid_phone          ON students(national_id, phone);
CREATE INDEX IF NOT EXISTS idx_students_nid_code           ON students(national_id, student_code);
CREATE INDEX IF NOT EXISTS idx_students_reg_ip_created     ON students(registration_ip, created_at);

-- -------------------------------------------------------------------
-- 3.4 فهارس الطلاب — جزئية (Partial) + فريدة + أداء مركب
-- -------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_students_ceremony_code      ON students(ceremony_code) WHERE ceremony_code IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_students_student_code ON students(student_code) WHERE student_code IS NOT NULL;

-- فهرس مركب لترتيب أداء الطلاب داخل كل مستوى
CREATE INDEX IF NOT EXISTS idx_students_level_id_score     ON students(level_id, score DESC NULLS LAST);

-- -------------------------------------------------------------------
-- 3.5 فهارس المستويات
-- -------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_levels_title                ON competition_levels(title);
CREATE INDEX IF NOT EXISTS idx_levels_active               ON competition_levels(is_active) WHERE is_active = TRUE;
CREATE UNIQUE INDEX IF NOT EXISTS idx_levels_code          ON competition_levels(level_code);


-- =================================================================================================
-- القسم الرابع: أمان الصفوف — Row Level Security
-- =================================================================================================

-- -------------------------------------------------------------------
-- 4.1 RLS — Students
-- -------------------------------------------------------------------
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert" ON students;

DROP POLICY IF EXISTS "Allow admin insert" ON students;
CREATE POLICY "Allow admin insert" ON students FOR INSERT WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Allow admin select" ON students;
CREATE POLICY "Allow admin select" ON students FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Allow admin update" ON students;
CREATE POLICY "Allow admin update" ON students FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Allow admin delete" ON students;
CREATE POLICY "Allow admin delete" ON students FOR DELETE USING (is_admin());

-- -------------------------------------------------------------------
-- 4.2 RLS — Admins
-- -------------------------------------------------------------------
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert to admins" ON admins;
DROP POLICY IF EXISTS "Allow admin insert to admins" ON admins;
CREATE POLICY "Allow admin insert to admins" ON admins FOR INSERT WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Allow admin select from admins" ON admins;
CREATE POLICY "Allow admin select from admins" ON admins FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Allow admin update" ON admins;
CREATE POLICY "Allow admin update" ON admins FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Allow admin delete" ON admins;
CREATE POLICY "Allow admin delete" ON admins FOR DELETE USING (is_admin());

-- -------------------------------------------------------------------
-- 4.3 RLS — Competition Levels
-- -------------------------------------------------------------------
ALTER TABLE competition_levels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public select from levels" ON competition_levels;
CREATE POLICY "Allow public select from levels" ON competition_levels FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow admin manage levels" ON competition_levels;
CREATE POLICY "Allow admin manage levels" ON competition_levels FOR ALL USING (is_admin());

-- -------------------------------------------------------------------
-- 4.4 RLS — App Settings
-- -------------------------------------------------------------------
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public select from settings" ON app_settings;
CREATE POLICY "Allow public select from settings" ON app_settings FOR SELECT USING (true);

DROP POLICY IF EXISTS "admins_update_app_settings" ON app_settings;
CREATE POLICY "admins_update_app_settings" ON app_settings
    FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

GRANT SELECT ON TABLE public.app_settings TO anon, authenticated;


-- =================================================================================================
-- القسم الخامس: دوال مساعدة مشتركة — Shared Helper Functions
-- =================================================================================================

-- -------------------------------------------------------------------
-- احتساب مجموع درجات الطالب
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_total_score(p_student students)
RETURNS DOUBLE PRECISION AS $$
BEGIN
    RETURN COALESCE(p_student.score, 0) + COALESCE(p_student.rewaya_score, 0) +
           COALESCE(p_student.tajweed_score, 0) + COALESCE(p_student.voice_score, 0) +
           COALESCE(p_student.meaning_score, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- -------------------------------------------------------------------
-- احتساب أقصى درجات المستوى
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_max_score(p_level competition_levels)
RETURNS INTEGER AS $$
BEGIN
    RETURN COALESCE(p_level.total_points, 100) +
           COALESCE(CASE WHEN p_level.has_rewaya THEN p_level.rewaya_max_score ELSE 0 END, 0) +
           COALESCE(CASE WHEN p_level.has_tajweed THEN p_level.tajweed_max_score ELSE 0 END, 0) +
           COALESCE(CASE WHEN p_level.has_voice THEN p_level.voice_max_score ELSE 0 END, 0) +
           COALESCE(CASE WHEN p_level.has_meaning THEN p_level.meaning_max_score ELSE 0 END, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- -------------------------------------------------------------------
-- توليد بادئة كود الطالب (حرف المستوى + رقم الجنس)
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_student_code_prefix(p_level TEXT, p_gender TEXT)
RETURNS TEXT AS $$
DECLARE
    v_level_code CHAR(1);
    v_gender_num CHAR(1);
BEGIN
    SELECT level_code INTO v_level_code FROM competition_levels WHERE title = p_level LIMIT 1;
    IF v_level_code IS NULL THEN v_level_code := 'X'; END IF;
    v_gender_num := CASE WHEN p_gender = 'ذكر' THEN '1' WHEN p_gender = 'أنثى' THEN '0' ELSE '9' END;
    RETURN v_level_code || v_gender_num;
END;
$$ LANGUAGE plpgsql STABLE;

-- =================================================================================================
-- القسم السادس: المحفزات — Triggers
-- =================================================================================================

-- -------------------------------------------------------------------
-- 5.1 تحديث تلقائي لـ updated_at (دالة واحدة لجميع الجداول)
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_students_updated_at ON students;
CREATE TRIGGER update_students_updated_at
    BEFORE UPDATE ON students FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_app_settings_updated_at ON app_settings;
CREATE TRIGGER trg_app_settings_updated_at
    BEFORE UPDATE ON app_settings FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_levels_updated_at ON competition_levels;
CREATE TRIGGER trg_levels_updated_at
    BEFORE UPDATE ON competition_levels FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- -------------------------------------------------------------------
-- 6.2 توليد كود المستوى (A, B, C...)
-- -------------------------------------------------------------------
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

DROP TRIGGER IF EXISTS trg_assign_level_code ON competition_levels;
CREATE TRIGGER trg_assign_level_code
    BEFORE INSERT ON competition_levels
    FOR EACH ROW WHEN (NEW.level_code IS NULL)
    EXECUTE FUNCTION assign_level_code();

-- -------------------------------------------------------------------
-- 6.3 جدولة مواعيد الاختبارات — FIFO Scheduling (محسّنة)
-- تملأ من أول ساعة متاحة في كل يوم (FIFO حقيقي)
-- تستخدم استعلام GROUP BY واحد بدلاً من N+1 لكل ساعة
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION assign_exam_slot()
RETURNS TRIGGER AS $$
DECLARE
    schedule_json  JSONB;
    slot           JSONB;
    v_date         DATE;
    v_start_hour   INT;
    v_end_hour     INT;
    v_students_per_hour INT;
    v_current_hour INT;
    assigned       BOOLEAN := FALSE;
    slot_counts    RECORD;
    v_slot_counts_json JSONB;
BEGIN
    PERFORM pg_advisory_xact_lock(987654321);
    SELECT exam_schedule INTO schedule_json FROM app_settings WHERE id = 1 LIMIT 1;

    IF schedule_json IS NULL OR jsonb_array_length(schedule_json) = 0 THEN
        NEW.notes := COALESCE(NEW.notes || E'\n', '') || 'تنبيه: لم يتم تحديد ميعاد (لا يوجد جدول)';
        RETURN NEW;
    END IF;

    -- استعلام واحد مجمع بدلاً من N+1 لكل ساعة
    SELECT jsonb_object_agg(exam_date::TEXT || '_' || exam_hour::TEXT, cnt)
    INTO v_slot_counts_json
    FROM (
        SELECT exam_date, exam_hour, COUNT(*) AS cnt
        FROM students
        WHERE exam_date IS NOT NULL AND exam_hour IS NOT NULL
        GROUP BY exam_date, exam_hour
    ) sub;

    -- ================================================================
    -- المرحلة الأولى: سد الثقوب الناتجة عن حذف طلاب (ترتيب زمني تصاعدي)
    -- الثقب الحقيقي = ساعة فيها طلاب (> 0) ولكن أقل من السعة
    -- ================================================================
    FOR slot IN
        SELECT value FROM jsonb_array_elements(schedule_json)
        ORDER BY (value->>'date')::DATE ASC, (value->>'start_hour')::INT ASC
    LOOP
        v_date              := (slot->>'date')::DATE;
        v_start_hour        := (slot->>'start_hour')::INT;
        v_end_hour          := (slot->>'end_hour')::INT;
        v_students_per_hour := (slot->>'students_per_hour')::INT;

        v_current_hour := v_start_hour;
        WHILE v_current_hour < v_end_hour LOOP
            DECLARE
                cnt BIGINT;
            BEGIN
                cnt := COALESCE((v_slot_counts_json->>(v_date::TEXT || '_' || v_current_hour::TEXT))::BIGINT, 0);
                -- ثقب حقيقي: فيه طلاب بس أقل من السعة (تم حذف بعضهم)
                IF cnt > 0 AND cnt < v_students_per_hour THEN
                    NEW.exam_date := v_date;
                    NEW.exam_hour := v_current_hour;
                    assigned := TRUE;
                    EXIT;
                END IF;
            END;
            v_current_hour := v_current_hour + 1;
        END LOOP;
        IF assigned THEN EXIT; END IF;
    END LOOP;

    -- ================================================================
    -- المرحلة الثانية: لا توجد ثقوب → توزيع LIFO من النهاية
    -- أول مسجل يحصل على آخر موعد
    -- ================================================================
    IF NOT assigned THEN
        FOR slot IN
            SELECT value FROM jsonb_array_elements(schedule_json)
            ORDER BY (value->>'date')::DATE DESC, (value->>'start_hour')::INT DESC
        LOOP
            v_date              := (slot->>'date')::DATE;
            v_start_hour        := (slot->>'start_hour')::INT;
            v_end_hour          := (slot->>'end_hour')::INT;
            v_students_per_hour := (slot->>'students_per_hour')::INT;

            v_current_hour := v_end_hour - 1;
            WHILE v_current_hour >= v_start_hour LOOP
                DECLARE
                    cnt BIGINT;
                BEGIN
                    cnt := COALESCE((v_slot_counts_json->>(v_date::TEXT || '_' || v_current_hour::TEXT))::BIGINT, 0);
                    IF cnt < v_students_per_hour THEN
                        NEW.exam_date := v_date;
                        NEW.exam_hour := v_current_hour;
                        assigned := TRUE;
                        EXIT;
                    END IF;
                END;
                v_current_hour := v_current_hour - 1;
            END LOOP;
            IF assigned THEN EXIT; END IF;
        END LOOP;
    END IF;

    IF NOT assigned THEN
        RAISE EXCEPTION 'عذراً، لقد اكتملت جميع المواعيد المتاحة حالياً ولا توجد أماكن شاغرة.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_assign_exam_slot ON students;
CREATE TRIGGER trigger_assign_exam_slot
    BEFORE INSERT ON students FOR EACH ROW
    EXECUTE FUNCTION assign_exam_slot();

-- -------------------------------------------------------------------
-- 6.4 توليد كود الطالب — Student Code (مثال: A1001)
-- تُستخدم get_student_code_prefix الدالة المساعدة المشتركة
-- تُستخدم regex بدلاً من LIKE لضمان مطابقة أرقام فقط
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_student_code()
RETURNS TRIGGER AS $$
DECLARE
    v_prefix TEXT;
    v_seq    INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(987654322);
    v_prefix := get_student_code_prefix(NEW.level, NEW.gender);

    SELECT COALESCE(
        (SELECT e.seq + 1
         FROM (
             SELECT SUBSTRING(student_code, 3)::int AS seq
             FROM students WHERE student_code ~ ('^' || v_prefix || '\d{3}$')
             UNION ALL SELECT 0
         ) e
         WHERE NOT EXISTS (
             SELECT 1 FROM students WHERE student_code = v_prefix || LPAD((e.seq + 1)::TEXT, 3, '0')
         )
         ORDER BY e.seq LIMIT 1),
        1
    ) INTO v_seq;

    NEW.student_code := v_prefix || LPAD(v_seq::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_student_code ON students;
CREATE TRIGGER trg_generate_student_code
    BEFORE INSERT ON students
    FOR EACH ROW WHEN (NEW.student_code IS NULL)
    EXECUTE FUNCTION generate_student_code();

-- -------------------------------------------------------------------
-- 6.5 إعادة توليد الكود عند تغيير المستوى أو النوع
-- تُستخدم get_student_code_prefix الدالة المساعدة المشتركة
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION regenerate_student_code_on_level_change()
RETURNS TRIGGER AS $$
DECLARE
    v_prefix TEXT;
    v_seq    INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(987654323);
    v_prefix := get_student_code_prefix(NEW.level, NEW.gender);

    SELECT COALESCE(
        (SELECT e.seq + 1
         FROM (
             SELECT SUBSTRING(student_code, 3)::int AS seq
             FROM students WHERE student_code ~ ('^' || v_prefix || '\d{3}$') AND id != OLD.id
             UNION ALL SELECT 0
         ) e
         WHERE NOT EXISTS (
             SELECT 1 FROM students
             WHERE student_code = v_prefix || LPAD((e.seq + 1)::TEXT, 3, '0') AND id != OLD.id
         )
         ORDER BY e.seq LIMIT 1),
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

-- -------------------------------------------------------------------
-- 6.6 مزامنة level_id تلقائياً من level (نص)
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_level_id()
RETURNS TRIGGER AS $$
BEGIN
    SELECT id INTO NEW.level_id FROM competition_levels WHERE title = NEW.level LIMIT 1;

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

-- -------------------------------------------------------------------
-- 6.7 فحص سعة المستوى — Capacity Check (باستخدام level_id)
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_level_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_capacity INTEGER;
    v_current  INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(987654325);

    -- يضمن sync_level_id أن level_id موجود قبل هذا المحفز
    SELECT max_capacity INTO v_capacity FROM competition_levels WHERE id = NEW.level_id;

    IF v_capacity IS NOT NULL THEN
        SELECT COUNT(*) INTO v_current FROM students WHERE level_id = NEW.level_id;
        IF v_current >= v_capacity THEN
            RAISE EXCEPTION 'المستوى المطلوب ممتلئ تماماً بالحد الأقصى للمتسابقين';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_level_capacity ON students;
CREATE TRIGGER trg_z_check_level_capacity
    BEFORE INSERT ON students FOR EACH ROW
    EXECUTE FUNCTION check_level_capacity();

-- -------------------------------------------------------------------
-- 6.8 حذف متسلسل للطلاب عند حذف المستوى
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cascade_delete_level_students()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM students WHERE level = OLD.title;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cascade_delete_level ON competition_levels;
CREATE TRIGGER trg_cascade_delete_level
    BEFORE DELETE ON competition_levels FOR EACH ROW
    EXECUTE FUNCTION cascade_delete_level_students();


-- =================================================================================================
-- القسم السابع: الدوال الداخلية — Internal Functions
-- =================================================================================================

-- -------------------------------------------------------------------
-- 7.1 التحقق من المدير
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM public.admins WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION is_admin() TO anon, authenticated;

-- -------------------------------------------------------------------
-- 7.2 إحصائيات أساسية (بدون فلاتر)
-- -------------------------------------------------------------------
DROP FUNCTION IF EXISTS get_student_stats();
CREATE FUNCTION get_student_stats()
RETURNS TABLE (total_students BIGINT, avg_score NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(*)::BIGINT, AVG(score) FILTER (WHERE score IS NOT NULL)::NUMERIC
    FROM students;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION get_student_stats() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_student_stats() TO authenticated;

-- -------------------------------------------------------------------
-- 7.3 إحصائيات متقدمة (مع فلاتر)
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_student_stats(
    p_level      TEXT DEFAULT NULL,
    p_gender     TEXT DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date   DATE DEFAULT NULL
)
RETURNS TABLE (
    total_students BIGINT,
    avg_score      NUMERIC,
    male_count     BIGINT,
    female_count   BIGINT,
    highest_score  NUMERIC
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

REVOKE EXECUTE ON FUNCTION get_student_stats(TEXT, TEXT, DATE, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_student_stats(TEXT, TEXT, DATE, DATE) TO authenticated;

-- -------------------------------------------------------------------
-- 7.4 حالة طالب كاملة — get_student_status
-- -------------------------------------------------------------------
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
    profile_image_url   TEXT,
    age                 INTEGER,
    gender              TEXT,
    phone               TEXT,
    national_id         TEXT,
    birth_certificate_url TEXT,
    memorizer_name      TEXT,
    memorizer_phone     TEXT,
    memorizer_address   TEXT,
    location            TEXT,
    selected_rewaya     TEXT,
    level_code          CHAR(1),
    first_prize         TEXT,
    second_prize        TEXT,
    third_prize         TEXT
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id, s.name, s.level, s.student_code, s.ceremony_code,
        s.exam_date, s.exam_hour, s.score, s.rewaya_score, s.tajweed_score,
        s.voice_score, s.meaning_score, s.profile_image_url, s.age, s.gender,
        s.phone, s.national_id, s.birth_certificate_url,
        s.memorizer_name, s.memorizer_phone, s.memorizer_address,
        s.location, s.selected_rewaya,
        cl.level_code, cl.first_prize, cl.second_prize, cl.third_prize
    FROM students s
    LEFT JOIN competition_levels cl ON cl.id = s.level_id
    WHERE s.national_id = p_national_id AND s.student_code = p_student_code;
END;
$$;

REVOKE EXECUTE ON FUNCTION get_student_status(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_student_status(TEXT, TEXT) TO authenticated;

-- -------------------------------------------------------------------
-- 7.5 استرجاع كود الطالب المفقود
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION retrieve_student_code(p_national_id TEXT, p_phone TEXT)
RETURNS TABLE (student_code TEXT, name TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT s.student_code::TEXT, s.name::TEXT
    FROM students s
    WHERE s.national_id = p_national_id AND s.phone = p_phone;
END;
$$;

REVOKE EXECUTE ON FUNCTION retrieve_student_code(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION retrieve_student_code(TEXT, TEXT) TO authenticated;


-- =================================================================================================
-- القسم الثامن: دوال الـ API العامة — Public API Functions
-- =================================================================================================
-- تستخدم من واجهة Next.js للاستعلامات العامة

-- -------------------------------------------------------------------
-- 8.1 البحث عن طالب — public_lookup_student
-- -------------------------------------------------------------------
DROP FUNCTION IF EXISTS public_lookup_student(TEXT);
DROP FUNCTION IF EXISTS public_lookup_student(TEXT, TEXT);
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

-- -------------------------------------------------------------------
-- 8.2 نتيجة طالب — public_lookup_result
-- -------------------------------------------------------------------
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

-- -------------------------------------------------------------------
-- 8.3 استعلام الحفل — public_lookup_ceremony
-- -------------------------------------------------------------------
-- ملاحظة: تحسب النسبة المئوية للمتسابق (total_score / max_score * 100)
-- وتقرر الأهلية بناءً على >= passing_percentage لكل مستوى
-- -------------------------------------------------------------------
DROP FUNCTION IF EXISTS public_lookup_ceremony(TEXT, TEXT);
DROP FUNCTION IF EXISTS public_lookup_ceremony(TEXT);
CREATE OR REPLACE FUNCTION public_lookup_ceremony(p_national_id TEXT)
RETURNS TABLE (
    id                INTEGER,
    name              TEXT,
    level             TEXT,
    level_content     TEXT,
    ceremony_code     TEXT,
    profile_image_url TEXT,
    age               INTEGER,
    student_code      TEXT,
    exam_date         DATE,
    exam_hour         INTEGER,
    level_code        CHAR(1),
    first_prize       TEXT,
    second_prize      TEXT,
    third_prize       TEXT,
    is_eligible       BOOLEAN,
    percentage        DOUBLE PRECISION,
    total_score       DOUBLE PRECISION,
    max_score         INTEGER
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_is_open BOOLEAN;
BEGIN
    SELECT is_ceremony_query_open INTO v_is_open FROM app_settings WHERE app_settings.id = 1;
    IF v_is_open IS NOT TRUE THEN
        RAISE EXCEPTION 'الاستعلام عن الحفل غير متاح حالياً.';
    END IF;

    RETURN QUERY
    WITH score_data AS (
        SELECT
            s.id,
            s.name,
            s.level,
            cl.content AS level_content,
            s.ceremony_code,
            s.profile_image_url,
            s.age,
            s.student_code,
            s.exam_date,
            s.exam_hour,
            cl.level_code,
            cl.first_prize,
            cl.second_prize,
            cl.third_prize,
            calculate_total_score(s) AS total_score,
            calculate_max_score(cl) AS max_score,
            COALESCE(cl.passing_percentage, 95) AS passing_pct
        FROM students s
        LEFT JOIN competition_levels cl ON cl.id = s.level_id
        WHERE s.national_id = p_national_id
          AND s.ceremony_code IS NOT NULL
    )
    SELECT
        sd.id,
        sd.name,
        sd.level,
        sd.level_content,
        sd.ceremony_code,
        sd.profile_image_url,
        sd.age,
        sd.student_code,
        sd.exam_date,
        sd.exam_hour,
        sd.level_code,
        sd.first_prize,
        sd.second_prize,
        sd.third_prize,
        CASE WHEN sd.max_score > 0 THEN (sd.total_score * 100.0 / sd.max_score) >= COALESCE(sd.passing_pct, 95) ELSE false END AS is_eligible,
        CASE WHEN sd.max_score > 0 THEN (sd.total_score * 100.0 / sd.max_score) ELSE 0 END AS percentage,
        sd.total_score,
        sd.max_score
    FROM score_data sd;
END;
$$;

GRANT EXECUTE ON FUNCTION public_lookup_ceremony(TEXT) TO anon, authenticated;

-- -------------------------------------------------------------------
-- 8.4 حالة التسجيل — public_get_registration_status
-- -------------------------------------------------------------------
DROP FUNCTION IF EXISTS public_get_registration_status();
CREATE OR REPLACE FUNCTION public_get_registration_status()
RETURNS TABLE (
    is_registration_open    BOOLEAN,
    has_available_slots     BOOLEAN,
    is_result_query_open    BOOLEAN,
    is_ceremony_query_open  BOOLEAN,
    result_query_open_date  TIMESTAMPTZ,
    ceremony_query_open_date TIMESTAMPTZ,
    competition_title       TEXT,
    total_slots             BIGINT,
    filled_slots            BIGINT,
    total_students          BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_total_slots  BIGINT := 0;
    v_filled_slots BIGINT := 0;
    v_total_students BIGINT := 0;
BEGIN
    SELECT COALESCE(SUM(
        ((slot->>'end_hour')::INT - (slot->>'start_hour')::INT) *
        COALESCE((slot->>'students_per_hour')::INT, 1)
    ), 0) INTO v_total_slots
    FROM app_settings, jsonb_array_elements(exam_schedule) AS slot
    WHERE app_settings.id = 1;

    SELECT COUNT(*) FILTER (WHERE exam_date IS NOT NULL AND exam_hour IS NOT NULL), COUNT(*)
    INTO v_filled_slots, v_total_students
    FROM students;

    RETURN QUERY
    SELECT
        s.is_registration_open,
        (v_total_slots > v_filled_slots),
        s.is_result_query_open,
        s.is_ceremony_query_open,
        s.result_query_open_date,
        s.ceremony_query_open_date,
        s.competition_title,
        v_total_slots,
        v_filled_slots,
        v_total_students
    FROM app_settings s
    WHERE s.id = 1;
END;
$$;

GRANT EXECUTE ON FUNCTION public_get_registration_status() TO anon, authenticated;

-- -------------------------------------------------------------------
-- 8.5 استعلام حضور الحفل (للإدارة) — query_ceremony_attendance
-- -------------------------------------------------------------------
DROP FUNCTION IF EXISTS query_ceremony_attendance(TEXT, TEXT);
CREATE OR REPLACE FUNCTION query_ceremony_attendance(p_national_id TEXT, p_phone TEXT DEFAULT NULL)
RETURNS TABLE (
    student_id    INTEGER,
    student_name  TEXT,
    student_level TEXT,
    student_image TEXT,
    ceremony_code TEXT
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_is_open BOOLEAN;
BEGIN
    SELECT is_ceremony_query_open INTO v_is_open FROM app_settings WHERE id = 1;

    IF v_is_open IS NOT TRUE THEN
        RAISE EXCEPTION 'الاستعلام عن حضور الحفل غير متاح حالياً.';
    END IF;

    RETURN QUERY
    SELECT s.id, s.name, s.level, s.profile_image_url, s.ceremony_code
    FROM students s
    WHERE s.national_id = p_national_id
      AND (p_phone IS NULL OR s.phone = p_phone)
      AND s.ceremony_code IS NOT NULL;
END;
$$;

REVOKE EXECUTE ON FUNCTION query_ceremony_attendance(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION query_ceremony_attendance(TEXT, TEXT) TO authenticated;


-- =================================================================================================
-- القسم التاسع: دوال الحفل — Ceremony Functions
-- =================================================================================================

-- -------------------------------------------------------------------
-- 9.1 توليد أكواد الحفل — generate_all_ceremony_codes (محسّنة)
-- تستخدم UPDATE مجمع بدلاً من N+1 تحديثات منفردة
-- تستخدم الدوال المساعدة calculate_total_score و calculate_max_score
-- تستخدم قفل منفصل (987654324) لتجنب التصادم مع جدولة الامتحان
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_all_ceremony_codes()
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    total_count INTEGER := 0;
    v_date_format TEXT;
BEGIN
    IF is_admin() IS NOT TRUE THEN
        RAISE EXCEPTION 'غير مصرح لك بتنفيذ هذا الإجراء.';
    END IF;

    SELECT COUNT(*) INTO total_count FROM students;
    IF total_count = 0 THEN
        RAISE EXCEPTION 'لا يوجد طلاب مسجلين في النظام. قم بإضافة طلاب أولاً.';
    END IF;

    PERFORM pg_advisory_xact_lock(987654324);

    -- مسح الأكواد القديمة
    UPDATE students SET ceremony_code = NULL WHERE ceremony_code IS NOT NULL;

    -- UPDATE مجمع واحد بدلاً من N+1
    WITH level_order AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS lev_num
        FROM competition_levels
    ),
    ranked AS (
        SELECT
            s.id,
            s.gender,
            lo.lev_num,
            calculate_total_score(s) AS total_score,
            calculate_max_score(cl) AS max_points,
            COALESCE(cl.passing_percentage, 95) AS passing_pct,
            ROW_NUMBER() OVER (
                PARTITION BY s.level_id
                ORDER BY calculate_total_score(s) DESC
            ) AS rank_in_level
        FROM students s
        JOIN competition_levels cl ON cl.id = s.level_id
        JOIN level_order lo ON lo.id = s.level_id
        WHERE s.level_id IS NOT NULL
    ),
    with_percentage AS (
        SELECT *,
            CASE WHEN max_points > 0 THEN (total_score * 100.0 / max_points) ELSE 0 END AS percentage
        FROM ranked
    ),
    with_codes AS (
        SELECT
            id,
            CASE WHEN gender = 'ذكر' THEN 'M' ELSE 'F' END || '-' ||
            LPAD(lev_num::TEXT, 2, '0') || '-' ||
            CASE
                WHEN lev_num <= 9 THEN
                    CASE WHEN (CASE WHEN max_points > 0 THEN (total_score * 100.0 / max_points) ELSE 0 END) >= COALESCE(passing_pct, 95)
                         THEN 'S' ELSE 'C' END
                ELSE
                    CASE WHEN rank_in_level <= 3 THEN 'S' ELSE 'C' END
            END || '-' ||
            LPAD((ROW_NUMBER() OVER (ORDER BY lev_num, total_score DESC) + 49)::TEXT, 3, '0') AS ceremony_code
        FROM with_percentage
    )
    UPDATE students s
    SET ceremony_code = wc.ceremony_code
    FROM with_codes wc
    WHERE s.id = wc.id;
END;
$$;

COMMENT ON FUNCTION generate_all_ceremony_codes() IS 'توليد أكواد الحفل. الأهلية: percentage >= passing_percentage للمستويات 1-9، وأفضل 3 للمستويات 10+';

REVOKE EXECUTE ON FUNCTION generate_all_ceremony_codes() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION generate_all_ceremony_codes() TO authenticated;
