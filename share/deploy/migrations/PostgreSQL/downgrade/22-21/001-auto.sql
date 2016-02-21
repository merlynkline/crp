-- Convert schema 'share/deploy/migrations/_source/deploy/22/001-auto.yml' to 'share/deploy/migrations/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructor_qualification DROP CONSTRAINT instructor_qualification_fk_qualification_id;

;
ALTER TABLE instructor_qualification ADD CONSTRAINT instructor_qualification_fk_qualification_id FOREIGN KEY (qualification_id)
  REFERENCES qualification (id) DEFERRABLE;

;

COMMIT;

