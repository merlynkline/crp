-- Convert schema 'share/deploy/migrations/_source/deploy/12/001-auto.yml' to 'share/deploy/migrations/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructors_course DROP COLUMN time;

;

COMMIT;

