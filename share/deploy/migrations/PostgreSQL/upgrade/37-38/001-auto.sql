-- Convert schema 'share/deploy/migrations/_source/deploy/37/001-auto.yml' to 'share/deploy/migrations/_source/deploy/38/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE qualification ADD COLUMN olccodes text;

;

COMMIT;

