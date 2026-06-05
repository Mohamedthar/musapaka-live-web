-- =============================================
-- Migration: Add Prize Columns to competition_levels
-- =============================================
-- Adds first_prize, second_prize, third_prize — individual prizes per rank.
-- Adds prizes — free-form text field for general prize description
--   (e.g. "الجائزة على أساس عدد الأجزاء المحفوظة").
-- These are displayed on the web /levels page.
-- If prizes is set, it takes priority over the individual fields on display.

ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS first_prize TEXT;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS second_prize TEXT;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS third_prize TEXT;
ALTER TABLE competition_levels ADD COLUMN IF NOT EXISTS prizes TEXT;
