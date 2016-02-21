-- Convert schema 'share/deploy/migrations/_source/deploy/20/001-auto.yml' to 'share/deploy/migrations/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructors_course ADD COLUMN qualification_id integer;

;
CREATE INDEX instructors_course_idx_qualification_id on instructors_course (qualification_id);

;
ALTER TABLE instructors_course ADD CONSTRAINT instructors_course_fk_qualification_id FOREIGN KEY (qualification_id)
  REFERENCES qualification (id) DEFERRABLE;

;

COMMIT;

