-- Convert schema 'share/deploy/migrations/_source/deploy/42/001-auto.yml' to 'share/deploy/migrations/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_student ALTER COLUMN progress SET NOT NULL;

;

COMMIT;

