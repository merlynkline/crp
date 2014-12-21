-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sun Dec 21 21:55:06 2014
-- 
;
--
-- Table: enquiry.
--
CREATE TABLE "enquiry" (
  "id" serial NOT NULL,
  "name" text,
  "email" text NOT NULL,
  "create_date" timestamptz DEFAULT (now()) NOT NULL,
  "suspend_date" timestamptz,
  "location" text,
  "latitude" numeric,
  "longitude" numeric,
  "notify_new_courses" boolean,
  "notify_tutors" boolean,
  "send_newsletter" boolean,
  PRIMARY KEY ("id"),
  CONSTRAINT "enquiry_email_key" UNIQUE ("email")
);
CREATE INDEX "enquiry_suspend_date_idx" on "enquiry" ("suspend_date");
CREATE INDEX "enquiry_latitude_idx" on "enquiry" ("latitude");
CREATE INDEX "enquiry_longitude_idx" on "enquiry" ("longitude");

;
--
-- Table: login.
--
CREATE TABLE "login" (
  "id" serial NOT NULL,
  "email" text,
  "create_date" timestamptz DEFAULT (now()) NOT NULL,
  "last_login_date" timestamptz,
  "password_hash" text,
  "otp_hash" text,
  "otp_expiry_date" timestamptz,
  "is_administrator" boolean,
  "auto_login" boolean,
  "disabled_date" timestamptz,
  PRIMARY KEY ("id"),
  CONSTRAINT "login_email_key" UNIQUE ("email")
);

;
--
-- Table: session.
--
CREATE TABLE "session" (
  "id" serial NOT NULL,
  "instructor_id" integer,
  "data" text,
  "last_access_date" timestamptz DEFAULT (now()) NOT NULL,
  PRIMARY KEY ("id")
);

;
--
-- Table: profile.
--
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
  "location" text,
  "latitude" numeric,
  "longitude" numeric,
  PRIMARY KEY ("instructor_id"),
  CONSTRAINT "web_page_slug_key" UNIQUE ("web_page_slug")
);
CREATE INDEX "profile_web_page_slug_idx" on "profile" ("web_page_slug");
CREATE INDEX "profile_latitude_idx" on "profile" ("latitude");
CREATE INDEX "profile_longitude_idx" on "profile" ("longitude");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "login" ADD CONSTRAINT "login_fk_id" FOREIGN KEY ("id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "profile" ADD CONSTRAINT "profile_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
