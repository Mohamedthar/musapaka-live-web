-- =============================================
-- Migration: إضافة العمود المفقود max_score
-- =============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'competition_levels'
                   AND column_name = 'max_score') THEN
        ALTER TABLE competition_levels ADD COLUMN max_score INTEGER DEFAULT 100;
    END IF;
END $$;
