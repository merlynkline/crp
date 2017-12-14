-- Convert schema 'share/deploy/migrations/_source/deploy/36/001-auto.yml' to 'share/deploy/migrations/_source/deploy/37/001-auto.yml':;

;
BEGIN;

;
CREATE INDEX olc_course_code_idx on olc_course (code);

;

COMMIT;

