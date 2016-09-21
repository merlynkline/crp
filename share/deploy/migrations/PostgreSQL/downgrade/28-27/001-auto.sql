-- Convert schema 'share/deploy/migrations/_source/deploy/28/001-auto.yml' to 'share/deploy/migrations/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instructor_qualification DROP CONSTRAINT instructor_qualification_fk_trainer_id;

;
DROP INDEX instructor_qualification_idx_trainer_id;

;
ALTER TABLE instructor_qualification DROP COLUMN trainer_id;

;

COMMIT;

