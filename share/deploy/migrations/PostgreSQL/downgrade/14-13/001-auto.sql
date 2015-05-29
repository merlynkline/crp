-- Convert schema 'share/deploy/migrations/_source/deploy/14/001-auto.yml' to 'share/deploy/migrations/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructors_course ADD COLUMN price text NOT NULL;

;

COMMIT;

