-- Convert schema 'share/deploy/migrations/_source/deploy/36/001-auto.yml' to 'share/deploy/migrations/_source/deploy/35/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_course DROP COLUMN code;

;
ALTER TABLE olc_course ADD COLUMN landing_olc_page_id integer;

;
ALTER TABLE olc_module ADD COLUMN landing_olc_page_id integer;

;

COMMIT;

