-- =============================================
-- Migration: إصلاح أنواع أعمدة الدرجات في جدول students
-- تغيير NUMERIC(5,2) → DOUBLE PRECISION لتطابق دوال RPC
-- =============================================

DO $$
BEGIN
    -- score
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'students'
          AND column_name = 'score' AND data_type = 'numeric'
    ) THEN
        ALTER TABLE students ALTER COLUMN score TYPE DOUBLE PRECISION;
    END IF;

    -- rewaya_score
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'students'
          AND column_name = 'rewaya_score' AND data_type = 'numeric'
    ) THEN
        ALTER TABLE students ALTER COLUMN rewaya_score TYPE DOUBLE PRECISION;
    END IF;

    -- tajweed_score
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'students'
          AND column_name = 'tajweed_score' AND data_type = 'numeric'
    ) THEN
        ALTER TABLE students ALTER COLUMN tajweed_score TYPE DOUBLE PRECISION;
    END IF;

    -- voice_score
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'students'
          AND column_name = 'voice_score' AND data_type = 'numeric'
    ) THEN
        ALTER TABLE students ALTER COLUMN voice_score TYPE DOUBLE PRECISION;
    END IF;

    -- meaning_score
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'students'
          AND column_name = 'meaning_score' AND data_type = 'numeric'
    ) THEN
        ALTER TABLE students ALTER COLUMN meaning_score TYPE DOUBLE PRECISION;
    END IF;
END $$;
