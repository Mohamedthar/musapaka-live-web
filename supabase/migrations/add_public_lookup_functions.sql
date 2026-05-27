-- =============================================
-- Migration: Add secure public lookup functions
-- تسمح للـ API routes باستخدام anon key بدل service_role
-- للاستعلام عن الطلاب والنتائج والحفل
-- =============================================
BEGIN;

-- 1. دالة آمنة للاستعلام عن الاستمارة (للعامة)
-- تحتاج رقم قومي فقط - ترجع بيانات محدودة بدون درجات
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

-- 2. دالة آمنة للاستعلام عن النتيجة
-- تحتاج رقم قومي وتتحقق من أن النتائج مفتوحة
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

-- 3. دالة آمنة للاستعلام عن الحفل
-- تحتاج رقم قومي وتتحقق من أن الاستعلام مفتوح
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

-- 4. دالة للتحقق من حالة التسجيل
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
        'end_date', registration_end_date
    ) INTO v_result
    FROM app_settings LIMIT 1;
    
    RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public_get_registration_status() TO anon, authenticated;

-- 5. دالة إحصائيات عامة للصفحة الرئيسية
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

COMMIT;
