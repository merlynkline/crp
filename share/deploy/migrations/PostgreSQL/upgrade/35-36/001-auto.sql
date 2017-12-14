-- Convert schema 'share/deploy/migrations/_source/deploy/35/001-auto.yml' to 'share/deploy/migrations/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_course DROP COLUMN landing_olc_page_id;

;
ALTER TABLE olc_course ADD COLUMN code text;

;
ALTER TABLE olc_module DROP COLUMN landing_olc_page_id;

;

COMMIT;

