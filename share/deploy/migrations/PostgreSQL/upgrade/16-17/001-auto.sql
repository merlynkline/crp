-- Convert schema 'share/deploy/migrations/_source/deploy/16/001-auto.yml' to 'share/deploy/migrations/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE course ADD COLUMN book_excluded boolean DEFAULT 'f' NOT NULL;

;

COMMIT;

