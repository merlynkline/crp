-- Convert schema 'share/deploy/migrations/_source/deploy/21/001-auto.yml' to 'share/deploy/migrations/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructors_course DROP CONSTRAINT instructors_course_fk_qualification_id;

;
DROP INDEX instructors_course_idx_qualification_id;

;
ALTER TABLE instructors_course DROP COLUMN qualification_id;

;

COMMIT;

