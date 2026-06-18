-- Migration: Replace is_cleared boolean with follow_up_status 3-state integer
-- 0 = default (not contacted), 1 = message sent, 2 = cleared (all good)

ALTER TABLE students
ADD COLUMN IF NOT EXISTS follow_up_status SMALLINT DEFAULT 0;

-- Migrate existing data: if is_cleared was true, set to 2
UPDATE students SET follow_up_status = 2 WHERE is_cleared = true;

-- Drop old column and index
DROP INDEX IF EXISTS idx_students_is_cleared;
ALTER TABLE students DROP COLUMN IF EXISTS is_cleared;

-- New index
CREATE INDEX IF NOT EXISTS idx_students_follow_up_status ON students(follow_up_status);
