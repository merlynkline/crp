-- Convert schema 'share/deploy/migrations/_source/deploy/35/001-auto.yml' to 'share/deploy/migrations/_source/deploy/34/001-auto.yml':;

;
BEGIN;

;
DROP INDEX olc_component_guid_idx;

;
ALTER TABLE olc_component DROP COLUMN guid;

;
ALTER TABLE olc_component DROP COLUMN last_update_date;

;
DROP INDEX olc_course_guid_idx;

;
ALTER TABLE olc_course DROP COLUMN guid;

;
ALTER TABLE olc_course DROP COLUMN last_update_date;

;
DROP INDEX olc_module_guid_idx;

;
ALTER TABLE olc_module DROP COLUMN guid;

;
ALTER TABLE olc_module DROP COLUMN last_update_date;

;
DROP INDEX olc_page_guid_idx;

;
ALTER TABLE olc_page DROP COLUMN guid;

;
ALTER TABLE olc_page DROP COLUMN last_update_date;

;

COMMIT;

