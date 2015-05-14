-- Convert schema 'share/deploy/migrations/_source/deploy/12/001-auto.yml' to 'share/deploy/migrations/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE login ADD CONSTRAINT login_fk_id FOREIGN KEY (id)
  REFERENCES login (id) DEFERRABLE;

;
ALTER TABLE profile DROP CONSTRAINT profile_fk_instructor_id;

;
ALTER TABLE profile DROP COLUMN instructor_trainer;

;
ALTER TABLE profile ADD CONSTRAINT profile_fk_instructor_id FOREIGN KEY (instructor_id)
  REFERENCES login (id) DEFERRABLE;

;
DROP TABLE instructors_course CASCADE;

;

COMMIT;

