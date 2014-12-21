-- Convert schema 'share/deploy/migrations/_source/deploy/10/001-auto.yml' to 'share/deploy/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE login DROP CONSTRAINT login_fk_id;

;
ALTER TABLE profile DROP CONSTRAINT profile_fk_instructor_id;

;
DROP INDEX profile_latitude_idx;

;
DROP INDEX profile_longitude_idx;

;
ALTER TABLE profile DROP COLUMN location;

;
ALTER TABLE profile DROP COLUMN latitude;

;
ALTER TABLE profile DROP COLUMN longitude;

;

COMMIT;

