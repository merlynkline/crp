-- Convert schema 'share/deploy/migrations/_source/deploy/17/001-auto.yml' to 'share/deploy/migrations/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE profile ADD COLUMN hide_address boolean DEFAULT 'f' NOT NULL;

;

COMMIT;

