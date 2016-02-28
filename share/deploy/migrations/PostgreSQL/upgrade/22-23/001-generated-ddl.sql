-- Convert schema 'share/deploy/migrations/_source/deploy/22/001-auto.yml' to 'share/deploy/migrations/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE course_type DROP CONSTRAINT course_type_fk_qualification_required_id;

;
ALTER TABLE course_type ADD COLUMN code text;

;
CREATE INDEX course_type_code_idx on course_type (code);

;
ALTER TABLE course_type ADD CONSTRAINT course_type_fk_qualification_required_id FOREIGN KEY (qualification_required_id)
  REFERENCES qualification (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE qualification ADD COLUMN code text;

;
CREATE INDEX qualification_code_idx on qualification (code);

;

COMMIT;

