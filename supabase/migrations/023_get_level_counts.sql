-- ===================================================================
-- Migration 023: دالة عد الطلاب لكل مستوى
-- تحل مشكلة عرض صفر طلاب بسبب حد 1000 صف في Supabase
-- ===================================================================
CREATE OR REPLACE FUNCTION get_level_counts()
RETURNS TABLE(level TEXT, cnt BIGINT)
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
  SELECT level, COUNT(*)::BIGINT
  FROM students
  WHERE level IS NOT NULL
  GROUP BY level
  ORDER BY COUNT(*) DESC;
$$;

GRANT EXECUTE ON FUNCTION get_level_counts() TO anon, authenticated;
