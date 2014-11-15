-- Convert schema 'share/deploy/migrations/_source/deploy/3/001-auto.yml' to 'share/deploy/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE enquiry ALTER COLUMN create_date SET DEFAULT now();

;
DROP TABLE login CASCADE;

;

COMMIT;

