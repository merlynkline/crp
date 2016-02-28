-- Convert schema 'share/deploy/migrations/_source/deploy/23/001-auto.yml' to 'share/deploy/migrations/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE course_type DROP CONSTRAINT course_type_fk_qualification_required_id;

;
DROP INDEX course_type_code_idx;

;
ALTER TABLE course_type DROP COLUMN code;

;
ALTER TABLE course_type ADD CONSTRAINT course_type_fk_qualification_required_id FOREIGN KEY (qualification_required_id)
  REFERENCES qualification (id) DEFERRABLE;

;
DROP INDEX qualification_code_idx;

;
ALTER TABLE qualification DROP COLUMN code;

;

COMMIT;

