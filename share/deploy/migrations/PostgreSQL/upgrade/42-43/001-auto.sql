-- Convert schema 'share/deploy/migrations/_source/deploy/42/001-auto.yml' to 'share/deploy/migrations/_source/deploy/43/001-auto.yml':;

;
BEGIN;

;
CREATE INDEX olc_student_status_idx on olc_student (status);

;

COMMIT;

