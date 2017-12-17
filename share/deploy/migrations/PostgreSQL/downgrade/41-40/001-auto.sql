-- Convert schema 'share/deploy/migrations/_source/deploy/41/001-auto.yml' to 'share/deploy/migrations/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
DROP INDEX student_identity_idx;

;
CREATE INDEX student_identity_idx on olc_student (id_type, id_foreign_key);

;

COMMIT;

