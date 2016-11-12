-- Convert schema 'share/deploy/migrations/_source/deploy/30/001-auto.yml' to 'share/deploy/migrations/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE course_type DROP COLUMN is_professional;

;
DROP TABLE professional CASCADE;

;

COMMIT;

