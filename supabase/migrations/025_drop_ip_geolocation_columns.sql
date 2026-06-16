-- 025_drop_ip_geolocation_columns.sql
-- إزالة أعمدة الموقع الجغرافي من جدول الطلاب

ALTER TABLE students DROP COLUMN IF EXISTS ip_city;
ALTER TABLE students DROP COLUMN IF EXISTS ip_region;
ALTER TABLE students DROP COLUMN IF EXISTS ip_lat;
ALTER TABLE students DROP COLUMN IF EXISTS ip_lng;
