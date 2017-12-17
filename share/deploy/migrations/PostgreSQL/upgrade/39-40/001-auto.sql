-- Convert schema 'share/deploy/migrations/_source/deploy/39/001-auto.yml' to 'share/deploy/migrations/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_student ADD COLUMN name text NOT NULL;

;
ALTER TABLE olc_student ADD COLUMN email text NOT NULL;

;

COMMIT;

