-- =============================================
-- Migration: Result Inquiry Status Toggle
-- =============================================

-- 1. إضافة عمود is_result_query_open إلى جدول app_settings
ALTER TABLE app_settings ADD COLUMN IF NOT EXISTS is_result_query_open BOOLEAN DEFAULT false;
