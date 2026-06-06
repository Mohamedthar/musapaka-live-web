-- =============================================
-- Migration: إضافة الأعمدة المفقودة من app_settings
-- result_query_open_date, ceremony_query_open_date
-- =============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'app_settings'
                   AND column_name = 'result_query_open_date') THEN
        ALTER TABLE app_settings ADD COLUMN result_query_open_date TIMESTAMPTZ;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'app_settings'
                   AND column_name = 'ceremony_query_open_date') THEN
        ALTER TABLE app_settings ADD COLUMN ceremony_query_open_date TIMESTAMPTZ;
    END IF;
END $$;
