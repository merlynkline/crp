-- Convert schema 'share/deploy/migrations/_source/deploy/40/001-auto.yml' to 'share/deploy/migrations/_source/deploy/39/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_student DROP COLUMN name;

;
ALTER TABLE olc_student DROP COLUMN email;

;

COMMIT;

