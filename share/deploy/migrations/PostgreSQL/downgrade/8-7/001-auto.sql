-- Convert schema 'share/deploy/migrations/_source/deploy/8/001-auto.yml' to 'share/deploy/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE profile DROP CONSTRAINT web_page_slug_key;

;

COMMIT;

