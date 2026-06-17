-- Migration: Add is_cleared column to students table
-- Purpose: Track which students have been reviewed/cleared (no issues)

ALTER TABLE students
ADD COLUMN IF NOT EXISTS is_cleared BOOLEAN DEFAULT false;

-- Index for quick filtering by cleared status
CREATE INDEX IF NOT EXISTS idx_students_is_cleared ON students(is_cleared);
