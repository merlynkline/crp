-- Convert schema 'share/deploy/migrations/_source/deploy/7/001-auto.yml' to 'share/deploy/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE profile ADD CONSTRAINT web_page_slug_key UNIQUE (web_page_slug);

;

COMMIT;

