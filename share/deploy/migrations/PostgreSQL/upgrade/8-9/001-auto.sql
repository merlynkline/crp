-- Convert schema 'share/deploy/migrations/_source/deploy/8/001-auto.yml' to 'share/deploy/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE login ADD COLUMN disabled_date timestamptz;

;

COMMIT;

