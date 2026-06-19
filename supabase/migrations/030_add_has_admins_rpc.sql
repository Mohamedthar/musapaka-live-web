-- 1. Create a SECURITY DEFINER function that bypasses RLS to check if any admin exists.
-- This is needed because the splash screen needs to check admin existence before login,
-- but unauthenticated users cannot query the admins table due to RLS policies.
CREATE OR REPLACE FUNCTION public.has_admins()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM public.admins LIMIT 1);
END;
$$;

GRANT EXECUTE ON FUNCTION public.has_admins() TO anon, authenticated;

-- 2. Fix first-admin creation: the existing INSERT policy "Allow admin insert to admins"
-- uses is_admin() which requires the user to already exist in admins — a chicken-and-egg
-- problem. Add a policy that allows the first admin to be created when the table is empty,
-- then falls back to the existing admin-only policy for subsequent inserts.
DROP POLICY IF EXISTS "Allow first admin creation" ON admins;
CREATE POLICY "Allow first admin creation" ON admins FOR INSERT
WITH CHECK (
    is_admin() OR NOT EXISTS (SELECT 1 FROM public.admins)
);
