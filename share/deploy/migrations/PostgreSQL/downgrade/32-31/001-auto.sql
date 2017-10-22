-- Convert schema 'share/deploy/migrations/_source/deploy/32/001-auto.yml' to 'share/deploy/migrations/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_Component DROP COLUMN notes;

;
ALTER TABLE olc_Component ADD COLUMN description text;

;
ALTER TABLE olc_course DROP COLUMN notes;

;
ALTER TABLE olc_module DROP COLUMN notes;

;
ALTER TABLE olc_page DROP COLUMN notes;

;

COMMIT;

