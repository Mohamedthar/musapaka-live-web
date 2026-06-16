-- 025_add_ip_geolocation_columns.sql
-- يضيف أعمدة الموقع الجغرافي المستخرجة من IP للتسجيل

ALTER TABLE students ADD COLUMN IF NOT EXISTS ip_city   TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS ip_region TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS ip_lat    DOUBLE PRECISION;
ALTER TABLE students ADD COLUMN IF NOT EXISTS ip_lng    DOUBLE PRECISION;
