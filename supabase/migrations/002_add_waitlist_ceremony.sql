-- =============================================
-- Migration: Add is_waitlisted and ceremony_code to students
-- =============================================
ALTER TABLE students ADD COLUMN IF NOT EXISTS is_waitlisted BOOLEAN DEFAULT false;
ALTER TABLE students ADD COLUMN IF NOT EXISTS ceremony_code TEXT;
ALTER TABLE app_settings ADD COLUMN IF NOT EXISTS is_ceremony_query_open BOOLEAN NOT NULL DEFAULT false;
