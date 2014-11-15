-- Convert schema 'share/deploy/migrations/_source/deploy/2/001-auto.yml' to 'share/deploy/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "login" (
  "id" serial NOT NULL,
  "email" text,
  "create_date" timestamp DEFAULT (now()) NOT NULL,
  "last_login_date" timestamp,
  "password_hash" text,
  "otp_hash" text,
  "otp_expiry_date" timestamp,
  "is_administrator" boolean,
  "auto_login" boolean,
  PRIMARY KEY ("id"),
  CONSTRAINT "login_email_key" UNIQUE ("email")
);

;
ALTER TABLE enquiry ALTER COLUMN create_date SET DEFAULT (now());

;

COMMIT;

