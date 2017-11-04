-- Convert schema 'share/deploy/migrations/_source/deploy/33/001-auto.yml' to 'share/deploy/migrations/_source/deploy/34/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_component ALTER COLUMN data_version DROP NOT NULL;

;

COMMIT;

