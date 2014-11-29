-- Convert schema 'share/deploy/migrations/_source/deploy/5/001-auto.yml' to 'share/deploy/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "profile" (
  "instructor_id" integer NOT NULL,
  "name" text,
  "address" text,
  "postcode" text,
  "telephone" text,
  "mobile" text,
  "photo" text,
  "blurb" text,
  "web_page_slug" text,
  PRIMARY KEY ("instructor_id")
);

;

COMMIT;

