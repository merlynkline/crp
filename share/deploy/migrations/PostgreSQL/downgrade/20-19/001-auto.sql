-- Convert schema 'share/deploy/migrations/_source/deploy/20/001-auto.yml' to 'share/deploy/migrations/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE course DROP CONSTRAINT course_fk_course_type_id;

;
DROP INDEX course_idx_course_type_id;

;
ALTER TABLE course DROP COLUMN course_type_id;

;
DROP TABLE course_type CASCADE;

;

COMMIT;

