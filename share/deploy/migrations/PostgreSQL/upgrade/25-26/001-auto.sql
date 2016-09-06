-- Convert schema 'share/deploy/migrations/_source/deploy/25/001-auto.yml' to 'share/deploy/migrations/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE course_type ADD COLUMN qualification_earned_id integer;

;
CREATE INDEX course_type_idx_qualification_earned_id on course_type (qualification_earned_id);

;
ALTER TABLE course_type ADD CONSTRAINT course_type_fk_qualification_earned_id FOREIGN KEY (qualification_earned_id)
  REFERENCES qualification (id) DEFERRABLE;

;
ALTER TABLE instructors_course DROP CONSTRAINT instructors_course_fk_qualification_id;

;
DROP INDEX instructors_course_idx_qualification_id;

;
ALTER TABLE instructors_course ADD COLUMN course_type_id integer;

;
ALTER TABLE instructors_course ADD COLUMN duration text;

;
CREATE INDEX instructors_course_idx_course_type_id on instructors_course (course_type_id);

;
ALTER TABLE instructors_course ADD CONSTRAINT instructors_course_fk_course_type_id FOREIGN KEY (course_type_id)
  REFERENCES course_type (id) DEFERRABLE;

;

COMMIT;

