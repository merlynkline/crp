-- Convert schema 'share/deploy/migrations/_source/deploy/27/001-auto.yml' to 'share/deploy/migrations/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructor_qualification ADD COLUMN trainer_id integer;

;
CREATE INDEX instructor_qualification_idx_trainer_id on instructor_qualification (trainer_id);

;
ALTER TABLE instructor_qualification ADD CONSTRAINT instructor_qualification_fk_trainer_id FOREIGN KEY (trainer_id)
  REFERENCES login (id) DEFERRABLE;

;

COMMIT;

