-- Convert schema 'share/deploy/migrations/_source/deploy/9/001-auto.yml' to 'share/deploy/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE login ADD CONSTRAINT login_fk_id FOREIGN KEY (id)
  REFERENCES login (id) DEFERRABLE;

;
ALTER TABLE profile ADD COLUMN location text;

;
ALTER TABLE profile ADD COLUMN latitude numeric;

;
ALTER TABLE profile ADD COLUMN longitude numeric;

;
CREATE INDEX profile_latitude_idx on profile (latitude);

;
CREATE INDEX profile_longitude_idx on profile (longitude);

;
ALTER TABLE profile ADD CONSTRAINT profile_fk_instructor_id FOREIGN KEY (instructor_id)
  REFERENCES login (id) DEFERRABLE;

;

COMMIT;

