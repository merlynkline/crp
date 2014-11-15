-- Convert schema 'share/deploy/migrations/_source/deploy/4/001-auto.yml' to 'share/deploy/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "session" (
  "id" serial NOT NULL,
  "instructor_id" integer,
  "data" text,
  "last_access_date" timestamptz DEFAULT (now()) NOT NULL,
  PRIMARY KEY ("id")
);

;

COMMIT;

