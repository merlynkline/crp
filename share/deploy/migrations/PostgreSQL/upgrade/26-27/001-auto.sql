-- Convert schema 'share/deploy/migrations/_source/deploy/26/001-auto.yml' to 'share/deploy/migrations/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructors_course DROP COLUMN qualification_id;

;
ALTER TABLE profile DROP COLUMN instructor_trainer;

;

COMMIT;

