-- =============================================
-- Migration: إزالة قيد العمر (students_age_check)
-- العمر أصبح يُحسب تلقائياً من تاريخ الميلاد
-- =============================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'students_age_check') THEN
        ALTER TABLE students DROP CONSTRAINT students_age_check;
    END IF;
END $$;
