-- Convert schema 'share/deploy/migrations/_source/deploy/6/001-auto.yml' to 'share/deploy/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
CREATE INDEX profile_web_page_slug_idx on profile (web_page_slug);

;

COMMIT;

