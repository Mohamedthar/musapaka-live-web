-- =============================================
-- Migration: إعادة بناء دالة توليد أكواد الحفل
-- الصيغة: M-01-S-050 = جنس-مستوى-مكان-رقم
-- =============================================

CREATE OR REPLACE FUNCTION generate_all_ceremony_codes()
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    student_rec RECORD;
    gender_char TEXT;
    level_num   TEXT;
    stage_char  TEXT;
    global_seq  INTEGER := 50;
    total_count INTEGER := 0;
BEGIN
    IF NOT is_admin() AND auth.uid() IS NOT NULL THEN
        RAISE EXCEPTION 'غير مصرح لك بتنفيذ هذا الإجراء.';
    END IF;

    SELECT COUNT(*) INTO total_count FROM students;
    IF total_count = 0 THEN
        RAISE EXCEPTION 'لا يوجد طلاب مسجلين في النظام. قم بإضافة طلاب أولاً.';
    END IF;

    PERFORM pg_advisory_xact_lock(987654321);

    -- مسح الأكواد القديمة
    UPDATE students SET ceremony_code = NULL WHERE ceremony_code IS NOT NULL;

    FOR student_rec IN
        WITH level_order AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS lev_num
            FROM competition_levels
        ),
        ranked_students AS (
            SELECT 
                s.id,
                s.gender,
                lo.lev_num,
                (COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + 
                 COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + 
                 COALESCE(s.meaning_score, 0)) AS total_score,
                (COALESCE(cl.total_points, 100) +
                 COALESCE(CASE WHEN cl.has_rewaya THEN cl.rewaya_max_score ELSE 0 END, 0) +
                 COALESCE(CASE WHEN cl.has_tajweed THEN cl.tajweed_max_score ELSE 0 END, 0) +
                 COALESCE(CASE WHEN cl.has_voice THEN cl.voice_max_score ELSE 0 END, 0) +
                 COALESCE(CASE WHEN cl.has_meaning THEN cl.meaning_max_score ELSE 0 END, 0)) AS max_points,
                ROW_NUMBER() OVER (
                    PARTITION BY s.level_id
                    ORDER BY (COALESCE(s.score, 0) + COALESCE(s.rewaya_score, 0) + 
                             COALESCE(s.tajweed_score, 0) + COALESCE(s.voice_score, 0) + 
                             COALESCE(s.meaning_score, 0)) DESC
                ) AS rank_in_level
            FROM students s
            JOIN competition_levels cl ON cl.id = s.level_id
            JOIN level_order lo ON lo.id = s.level_id
            WHERE s.level_id IS NOT NULL
        )
        SELECT *, 
            CASE WHEN max_points > 0 
                 THEN (total_score * 100.0 / max_points) 
                 ELSE 0 
            END AS percentage
        FROM ranked_students
        ORDER BY lev_num, total_score DESC
    LOOP
        gender_char := CASE WHEN student_rec.gender = 'ذكر' THEN 'M' ELSE 'F' END;

        level_num := LPAD(student_rec.lev_num::TEXT, 2, '0');

        IF student_rec.lev_num <= 9 THEN
            stage_char := CASE WHEN student_rec.percentage >= 95 THEN 'S' ELSE 'C' END;
        ELSE
            stage_char := CASE WHEN student_rec.rank_in_level <= 3 THEN 'S' ELSE 'C' END;
        END IF;

        UPDATE students
        SET ceremony_code = gender_char || '-' || level_num || '-' || stage_char || '-' || LPAD(global_seq::TEXT, 3, '0')
        WHERE id = student_rec.id;

        global_seq := global_seq + 1;
    END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION generate_all_ceremony_codes() TO authenticated;
