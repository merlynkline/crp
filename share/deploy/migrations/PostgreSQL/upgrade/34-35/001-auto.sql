-- Convert schema 'share/deploy/migrations/_source/deploy/34/001-auto.yml' to 'share/deploy/migrations/_source/deploy/35/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_component ADD COLUMN guid text;

;
ALTER TABLE olc_component ADD COLUMN last_update_date timestamptz;

;
CREATE INDEX olc_component_guid_idx on olc_component (guid);

;
ALTER TABLE olc_course ADD COLUMN guid text;

;
ALTER TABLE olc_course ADD COLUMN last_update_date timestamptz;

;
CREATE INDEX olc_course_guid_idx on olc_course (guid);

;
ALTER TABLE olc_module ADD COLUMN guid text;

;
ALTER TABLE olc_module ADD COLUMN last_update_date timestamptz;

;
CREATE INDEX olc_module_guid_idx on olc_module (guid);

;
ALTER TABLE olc_page ADD COLUMN guid text;

;
ALTER TABLE olc_page ADD COLUMN last_update_date timestamptz;

;
CREATE INDEX olc_page_guid_idx on olc_page (guid);

;

COMMIT;

