-- Convert schema 'share/deploy/migrations/_source/deploy/27/001-auto.yml' to 'share/deploy/migrations/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructors_course ADD COLUMN qualification_id integer;

;
ALTER TABLE profile ADD COLUMN instructor_trainer boolean DEFAULT '0' NOT NULL;

;

COMMIT;

