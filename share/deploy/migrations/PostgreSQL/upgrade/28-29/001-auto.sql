-- Convert schema 'share/deploy/migrations/_source/deploy/28/001-auto.yml' to 'share/deploy/migrations/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "premium_authorisation" (
  "id" serial NOT NULL,
  "create_date" timestamptz DEFAULT (now()) NOT NULL,
  "directory" text NOT NULL,
  "email" text NOT NULL,
  "name" text NOT NULL,
  "is_disabled" boolean NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "premium_authorisation_email_idx" on "premium_authorisation" ("email");

;
CREATE TABLE "premium_cookie_log" (
  "id" serial NOT NULL,
  "timestamp" timestamptz DEFAULT (now()) NOT NULL,
  "auth_id" integer NOT NULL,
  "remote_id" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "premium_cookie_log_idx_auth_id" on "premium_cookie_log" ("auth_id");

;
ALTER TABLE "premium_cookie_log" ADD CONSTRAINT "premium_cookie_log_fk_auth_id" FOREIGN KEY ("auth_id")
  REFERENCES "premium_authorisation" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

