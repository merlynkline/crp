-- Convert schema 'share/deploy/migrations/_source/deploy/26/001-auto.yml' to 'share/deploy/migrations/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE course_type DROP CONSTRAINT course_type_fk_qualification_earned_id;

;
DROP INDEX course_type_idx_qualification_earned_id;

;
ALTER TABLE course_type DROP COLUMN qualification_earned_id;

;
ALTER TABLE instructors_course DROP CONSTRAINT instructors_course_fk_course_type_id;

;
DROP INDEX instructors_course_idx_course_type_id;

;
ALTER TABLE instructors_course DROP COLUMN course_type_id;

;
ALTER TABLE instructors_course DROP COLUMN duration;

;
CREATE INDEX instructors_course_idx_qualification_id on instructors_course (qualification_id);

;
ALTER TABLE instructors_course ADD CONSTRAINT instructors_course_fk_qualification_id FOREIGN KEY (qualification_id)
  REFERENCES qualification (id) DEFERRABLE;

;

COMMIT;

