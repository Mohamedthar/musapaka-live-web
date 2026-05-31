-- Fix: generate_all_ceremony_codes - إضافة WHERE لتجنب خطأ PostgREST
-- المشكلة: PostgREST يرفض UPDATE بدون WHERE clause حتى داخل RPC functions

CREATE OR REPLACE FUNCTION generate_all_ceremony_codes()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF pg_try_advisory_xact_lock(987654324) = FALSE THEN
        RAISE EXCEPTION 'عملية توليد الأكواد جارية بالفعل، يرجى المحاولة لاحقاً.';
    END IF;

    -- إضافة WHERE clause لتجنب خطأ PostgREST "UPDATE requires a WHERE clause"
    UPDATE students SET ceremony_code = NULL WHERE id IS NOT NULL;

    WITH honored_students AS (
        SELECT 
            s.id,
            s.gender,
            s.age,
            COALESCE(ASCII(c.level_code) - 64, 24) AS level_num,
            (
                COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0)
            ) AS total_score,
            DENSE_RANK() OVER (PARTITION BY s.level_id ORDER BY (
                COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0)
            ) DESC) as level_rank,
            ROW_NUMBER() OVER (ORDER BY COALESCE(ASCII(c.level_code), 88) ASC, (
                COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0)
            ) DESC, s.name ASC) as global_seq
        FROM students s
        JOIN competition_levels c ON c.id = s.level_id
        WHERE (
            c.total_points + 
            CASE WHEN c.has_rewaya THEN COALESCE(c.rewaya_max_score, 0) ELSE 0 END +
            CASE WHEN c.has_tajweed THEN COALESCE(c.tajweed_max_score, 0) ELSE 0 END +
            CASE WHEN c.has_voice THEN COALESCE(c.voice_max_score, 0) ELSE 0 END +
            CASE WHEN c.has_meaning THEN COALESCE(c.meaning_max_score, 0) ELSE 0 END
        ) > 0
          AND (
            (COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + COALESCE(s.meaning_score, 0))::NUMERIC / 
            (
                c.total_points + 
                CASE WHEN c.has_rewaya THEN COALESCE(c.rewaya_max_score, 0) ELSE 0 END +
                CASE WHEN c.has_tajweed THEN COALESCE(c.tajweed_max_score, 0) ELSE 0 END +
                CASE WHEN c.has_voice THEN COALESCE(c.voice_max_score, 0) ELSE 0 END +
                CASE WHEN c.has_meaning THEN COALESCE(c.meaning_max_score, 0) ELSE 0 END
            )::NUMERIC * 100
          ) >= 95
    )
    UPDATE students
    SET ceremony_code = 
        CASE WHEN h.gender = 'ذكر' THEN 'M' ELSE 'F' END || '-' || 
        h.level_num::TEXT || '-' ||
        CASE 
            WHEN h.level_num <= 9 THEN 'S'
            WHEN h.age >= 18 THEN 'S'
            WHEN h.level_rank <= 3 THEN 'S'
            ELSE 'C' 
        END || '-' ||
        LPAD(h.global_seq::TEXT, 3, '0')
    FROM honored_students h
    WHERE students.id = h.id;
END;
$$;
