-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Fri Nov 28 22:48:20 2014
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
  PRIMARY KEY ("id"),
  CONSTRAINT "login_email_key" UNIQUE ("email")
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
  PRIMARY KEY ("instructor_id")
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
