-- ============================================================================
-- 034_fix_auth_functions.sql
-- اصلاح دوال المصادقة: استبدال supabase_auth مع تثبيت pgcrypto
-- ============================================================================

-- 1. تثبيت pgcrypto في public schema
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- 2. اصلاح create_admin_user
CREATE OR REPLACE FUNCTION create_admin_user(p_name TEXT, p_phone TEXT, p_password TEXT, p_role TEXT DEFAULT 'admin')
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
DECLARE
    v_current_role TEXT;
    v_current_id UUID;
    v_user_id UUID;
    v_email TEXT;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول اولا'; END IF;

    SELECT role INTO v_current_role FROM admins WHERE id = v_current_id;
    IF v_current_role IS NULL OR v_current_role != 'super_admin' THEN
        RAISE EXCEPTION 'فقط المسؤول الاعلى يمكنه انشاء حسابات مسؤولين جدد';
    END IF;

    IF p_role NOT IN ('super_admin', 'admin', 'viewer') THEN
        RAISE EXCEPTION 'الصلاحية يجب ان تكون: super_admin, admin, او viewer';
    END IF;

    v_email := p_phone || '@admin.com';

    IF EXISTS (SELECT 1 FROM admins WHERE phone = p_phone) THEN
        RAISE EXCEPTION 'يوجد مسؤول بهذا الرقم بالفعل';
    END IF;

    IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
        RAISE EXCEPTION 'يوجد حساب بهذا الرقم بالفعل';
    END IF;

    v_user_id := gen_random_uuid();

    INSERT INTO auth.users (
        id, instance_id, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, aud, role, created_at, updated_at
    ) VALUES (
        v_user_id,
        '00000000-0000-0000-0000-000000000000',
        v_email,
        crypt(p_password, gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('name', p_name, 'phone', p_phone),
        'authenticated',
        'authenticated',
        now(),
        now()
    );

    INSERT INTO auth.identities (
        id, user_id, identity_data, provider, created_at, updated_at
    ) VALUES (
        gen_random_uuid(), v_user_id,
        jsonb_build_object('sub', v_user_id::text, 'email', v_email),
        'email', now(), now()
    );

    INSERT INTO admins (id, name, phone, role) VALUES (v_user_id, p_name, p_phone, p_role);

    RETURN jsonb_build_object('id', v_user_id, 'name', p_name, 'phone', p_phone, 'role', p_role);
END;
$$;
GRANT EXECUTE ON FUNCTION create_admin_user(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- 3. اصلاح update_admin_password
CREATE OR REPLACE FUNCTION update_admin_password(p_admin_id UUID, p_new_password TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
DECLARE
    v_current_role TEXT;
    v_current_id UUID;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول اولا'; END IF;

    SELECT role INTO v_current_role FROM admins WHERE id = v_current_id;
    IF v_current_role IS NULL OR v_current_role != 'super_admin' THEN
        RAISE EXCEPTION 'فقط المسؤول الاعلى يمكنه تغيير كلمات المرور';
    END IF;

    IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
        RAISE EXCEPTION 'كلمة المرور يجب ان تكون 6 احرف على الاقل';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_admin_id) THEN
        RAISE EXCEPTION 'المسؤول غير موجود';
    END IF;

    UPDATE auth.users
    SET encrypted_password = crypt(p_new_password, gen_salt('bf')), updated_at = now()
    WHERE id = p_admin_id;
END;
$$;
GRANT EXECUTE ON FUNCTION update_admin_password(UUID, TEXT) TO authenticated;

-- 4. اصلاح change_my_password
CREATE OR REPLACE FUNCTION change_my_password(p_new_password TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public'
AS $$
DECLARE
    v_current_id UUID;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول اولا'; END IF;

    IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
        RAISE EXCEPTION 'كلمة المرور الجديدة يجب ان تكون 6 احرف على الاقل';
    END IF;

    UPDATE auth.users
    SET encrypted_password = crypt(p_new_password, gen_salt('bf')), updated_at = now()
    WHERE id = v_current_id;
END;
$$;
GRANT EXECUTE ON FUNCTION change_my_password(TEXT) TO authenticated;
