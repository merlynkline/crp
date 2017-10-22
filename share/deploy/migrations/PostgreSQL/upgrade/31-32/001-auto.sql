-- Convert schema 'share/deploy/migrations/_source/deploy/31/001-auto.yml' to 'share/deploy/migrations/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_component DROP COLUMN description;

;
ALTER TABLE olc_component ADD COLUMN notes text;

;
ALTER TABLE olc_course ADD COLUMN notes text;

;
ALTER TABLE olc_module ADD COLUMN notes text;

;
ALTER TABLE olc_page ADD COLUMN notes text;

;

COMMIT;

