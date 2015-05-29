-- Convert schema 'share/deploy/migrations/_source/deploy/15/001-auto.yml' to 'share/deploy/migrations/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructors_course DROP COLUMN price;

;

COMMIT;

