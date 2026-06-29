-- ============================================================================
-- 033_admin_management.sql
-- إدارة المسؤولين: صلاحيات، إضافة، حذف، عرض
-- ============================================================================

-- 1. إضافة عمود role لجدول admins (إن لم يكن موجوداً)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'admins'
          AND column_name = 'role'
    ) THEN
        ALTER TABLE public.admins ADD COLUMN role TEXT NOT NULL DEFAULT 'super_admin';
    END IF;
END $$;

UPDATE public.admins SET role = 'super_admin' WHERE role IS NULL OR role = '';

-- 2. عرض كل المسؤولين
CREATE OR REPLACE FUNCTION list_admins()
RETURNS TABLE(id UUID, name TEXT, phone TEXT, role TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'غير مصرح لك بعرض قائمة المسؤولين';
    END IF;
    RETURN QUERY SELECT a.id, a.name, a.phone, a.role, a.created_at FROM admins a ORDER BY a.created_at ASC;
END;
$$;
GRANT EXECUTE ON FUNCTION list_admins() TO authenticated;

-- 3. حذف مسؤول
CREATE OR REPLACE FUNCTION delete_admin_user(p_admin_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_current_role TEXT; v_current_id UUID;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
    SELECT role INTO v_current_role FROM public.admins WHERE id = v_current_id;
    IF v_current_role IS NULL OR v_current_role != 'super_admin' THEN
        RAISE EXCEPTION 'فقط المسؤول الأعلى يمكنه حذف حسابات المسؤولين';
    END IF;
    IF p_admin_id = v_current_id THEN RAISE EXCEPTION 'لا يمكنك حذف حسابك الحالي'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.admins WHERE id = p_admin_id) THEN
        RAISE EXCEPTION 'المسؤول غير موجود';
    END IF;
    DELETE FROM public.admins WHERE id = p_admin_id;
    BEGIN
        DELETE FROM auth.users WHERE id = p_admin_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'تم حذف المسؤول من التطبيق. قد تحتاج لإزالة المستخدم يدوياً من لوحة تحكم Supabase.';
    END;
END;
$$;
GRANT EXECUTE ON FUNCTION delete_admin_user(UUID) TO authenticated;

-- 4. تحديث صلاحية مسؤول
CREATE OR REPLACE FUNCTION update_admin_role(p_admin_id UUID, p_role TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_current_role TEXT; v_current_id UUID;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
    SELECT role INTO v_current_role FROM public.admins WHERE id = v_current_id;
    IF v_current_role IS NULL OR v_current_role != 'super_admin' THEN
        RAISE EXCEPTION 'فقط المسؤول الأعلى يمكنه تغيير صلاحيات المسؤولين';
    END IF;
    IF p_role NOT IN ('super_admin', 'admin', 'viewer') THEN
        RAISE EXCEPTION 'الصلاحية يجب أن تكون: super_admin, admin, أو viewer';
    END IF;
    IF p_admin_id = v_current_id THEN RAISE EXCEPTION 'لا يمكنك تغيير صلاحية حسابك الحالي'; END IF;
    UPDATE public.admins SET role = p_role WHERE id = p_admin_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'المسؤول غير موجود'; END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION update_admin_role(UUID, TEXT) TO authenticated;

-- 5. بيانات المسؤول الحالي
CREATE OR REPLACE FUNCTION get_current_admin()
RETURNS TABLE(id UUID, name TEXT, phone TEXT, role TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY SELECT a.id, a.name, a.phone, a.role, a.created_at FROM admins a WHERE a.id = auth.uid() LIMIT 1;
END;
$$;
GRANT EXECUTE ON FUNCTION get_current_admin() TO authenticated;

-- 6. إنشاء مسؤول جديد (يستخدم supabase_auth الداخلية - مش محتاج pgcrypto)
CREATE OR REPLACE FUNCTION create_admin_user(p_name TEXT, p_phone TEXT, p_password TEXT, p_role TEXT DEFAULT 'admin')
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_current_role TEXT; v_current_id UUID; v_user_id UUID; v_email TEXT;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
    SELECT role INTO v_current_role FROM public.admins WHERE id = v_current_id;
    IF v_current_role IS NULL OR v_current_role != 'super_admin' THEN
        RAISE EXCEPTION 'فقط المسؤول الأعلى يمكنه إنشاء حسابات مسؤولين جدد';
    END IF;
    IF p_role NOT IN ('super_admin', 'admin', 'viewer') THEN
        RAISE EXCEPTION 'الصلاحية يجب أن تكون: super_admin, admin, أو viewer';
    END IF;
    v_email := p_phone || '@admin.com';
    IF EXISTS (SELECT 1 FROM public.admins WHERE phone = p_phone) THEN
        RAISE EXCEPTION 'يوجد مسؤول بهذا الرقم بالفعل';
    END IF;
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
        RAISE EXCEPTION 'يوجد حساب بهذا الرقم بالفعل';
    END IF;

    -- استخدام دالة Supabase الداخلية لإنشاء المستخدم (بتتعامل مع التشفير تلقائياً)
    v_user_id := supabase_auth.create_user(
        email := v_email,
        password := p_password,
        email_confirm := true,
        user_metadata := jsonb_build_object('name', p_name, 'phone', p_phone)
    );

    INSERT INTO public.admins (id, name, phone, role) VALUES (v_user_id, p_name, p_phone, p_role);
    RETURN jsonb_build_object('id', v_user_id, 'name', p_name, 'phone', p_phone, 'role', p_role);
END;
$$;
GRANT EXECUTE ON FUNCTION create_admin_user(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- 7. إصدار المصادقة (لتسجيل خروج الجميع)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'app_settings' AND column_name = 'auth_version') THEN
        ALTER TABLE public.app_settings ADD COLUMN auth_version INTEGER NOT NULL DEFAULT 1;
    END IF;
END $$;

CREATE OR REPLACE FUNCTION force_logout_all_admins()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_current_role TEXT; v_current_id UUID; v_new_version INTEGER;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
    SELECT role INTO v_current_role FROM public.admins WHERE id = v_current_id;
    IF v_current_role IS NULL OR v_current_role != 'super_admin' THEN
        RAISE EXCEPTION 'فقط المسؤول الأعلى يمكنه تسجيل خروج جميع المسؤولين';
    END IF;
    UPDATE public.app_settings SET auth_version = auth_version + 1, updated_at = now() WHERE id = 1 RETURNING auth_version INTO v_new_version;
    RETURN v_new_version;
END;
$$;
GRANT EXECUTE ON FUNCTION force_logout_all_admins() TO authenticated;

CREATE OR REPLACE FUNCTION get_auth_version()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_version INTEGER;
BEGIN
    SELECT auth_version INTO v_version FROM public.app_settings WHERE id = 1;
    RETURN COALESCE(v_version, 1);
END;
$$;
GRANT EXECUTE ON FUNCTION get_auth_version() TO anon, authenticated;

-- 8. تغيير كلمة مرور أي مسؤول (يستخدم supabase_auth الداخلية)
CREATE OR REPLACE FUNCTION update_admin_password(p_admin_id UUID, p_new_password TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_current_role TEXT; v_current_id UUID;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
    SELECT role INTO v_current_role FROM public.admins WHERE id = v_current_id;
    IF v_current_role IS NULL OR v_current_role != 'super_admin' THEN
        RAISE EXCEPTION 'فقط المسؤول الأعلى يمكنه تغيير كلمات المرور';
    END IF;
    IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
        RAISE EXCEPTION 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_admin_id) THEN
        RAISE EXCEPTION 'المسؤول غير موجود';
    END IF;
    -- دالة Supabase الداخلية للتعامل مع التشفير تلقائياً
    PERFORM supabase_auth.update_user(uid := p_admin_id, password := p_new_password);
END;
$$;
GRANT EXECUTE ON FUNCTION update_admin_password(UUID, TEXT) TO authenticated;

-- 9. تغيير كلمة المرور الخاصة بي (يستخدم supabase_auth الداخلية)
-- ملاحظة: التحقق من كلمة المرور القديمة بيحصل في تطبيق Flutter قبل استدعاء هذه الدالة
CREATE OR REPLACE FUNCTION change_my_password(p_new_password TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_current_id UUID;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
    IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
        RAISE EXCEPTION 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل';
    END IF;
    PERFORM supabase_auth.update_user(uid := v_current_id, password := p_new_password);
END;
$$;
GRANT EXECUTE ON FUNCTION change_my_password(TEXT) TO authenticated;

-- 10. تحديث بيانات مسؤول
CREATE OR REPLACE FUNCTION update_admin_info(p_admin_id UUID, p_name TEXT, p_phone TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_current_role TEXT; v_current_id UUID; v_old_phone TEXT; v_new_email TEXT;
BEGIN
    v_current_id := auth.uid();
    IF v_current_id IS NULL THEN RAISE EXCEPTION 'يجب تسجيل الدخول أولاً'; END IF;
    SELECT role INTO v_current_role FROM public.admins WHERE id = v_current_id;
    IF v_current_role IS NULL OR v_current_role != 'super_admin' THEN
        RAISE EXCEPTION 'فقط المسؤول الأعلى يمكنه تعديل بيانات المسؤولين';
    END IF;
    IF p_name IS NULL OR trim(p_name) = '' THEN RAISE EXCEPTION 'الاسم مطلوب'; END IF;
    IF p_phone IS NULL OR trim(p_phone) = '' THEN RAISE EXCEPTION 'رقم الهاتف مطلوب'; END IF;
    IF EXISTS (SELECT 1 FROM public.admins WHERE phone = p_phone AND id != p_admin_id) THEN
        RAISE EXCEPTION 'يوجد مسؤول آخر بهذا الرقم';
    END IF;
    SELECT phone INTO v_old_phone FROM public.admins WHERE id = p_admin_id;
    UPDATE public.admins SET name = p_name, phone = p_phone WHERE id = p_admin_id;
    IF v_old_phone IS NOT NULL AND v_old_phone != p_phone THEN
        v_new_email := p_phone || '@admin.com';
        IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_new_email AND id != p_admin_id) THEN
            RAISE EXCEPTION 'يوجد حساب آخر بنفس البريد الإلكتروني';
        END IF;
        UPDATE auth.users SET email = v_new_email, updated_at = now() WHERE id = p_admin_id;
    END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION update_admin_info(UUID, TEXT, TEXT) TO authenticated;
