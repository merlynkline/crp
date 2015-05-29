-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Fri May 29 23:10:41 2015
-- 
;
--
-- Table: enquiry
--
CREATE TABLE "enquiry" (
  "id" serial NOT NULL,
  "name" text,
  "email" text NOT NULL,
  "create_date" timestamptz DEFAULT (now()) NOT NULL,
  "suspend_date" timestamptz,
  "location" text,
  "latitude" real,
  "longitude" real,
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
-- Table: login
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
-- Table: session
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
-- Table: audit
--
CREATE TABLE "audit" (
  "id" serial NOT NULL,
  "timestamp" timestamptz DEFAULT (now()) NOT NULL,
  "course_id" integer,
  "instructor_id" integer,
  "event_type" text NOT NULL,
  "details" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "audit_idx_course_id" on "audit" ("course_id");
CREATE INDEX "audit_idx_instructor_id" on "audit" ("instructor_id");
CREATE INDEX "profile_instructor_id_idx" on "audit" ("instructor_id");
CREATE INDEX "profile_course_id_idx" on "audit" ("course_id");
CREATE INDEX "profile_timestamp_idx" on "audit" ("timestamp");

;
--
-- Table: course
--
CREATE TABLE "course" (
  "id" serial NOT NULL,
  "instructor_id" integer NOT NULL,
  "location" text,
  "latitude" real,
  "longitude" real,
  "venue" text NOT NULL,
  "description" text NOT NULL,
  "start_date" timestamptz DEFAULT (now()) NOT NULL,
  "time" text NOT NULL,
  "price" text NOT NULL,
  "session_duration" text NOT NULL,
  "course_duration" text NOT NULL,
  "canceled" boolean NOT NULL,
  "published" boolean NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "course_idx_instructor_id" on "course" ("instructor_id");
CREATE INDEX "course_latitude_idx" on "course" ("latitude");
CREATE INDEX "course_longitude_idx" on "course" ("longitude");
CREATE INDEX "course_instructor_id_idx" on "course" ("instructor_id");

;
--
-- Table: instructors_course
--
CREATE TABLE "instructors_course" (
  "id" serial NOT NULL,
  "instructor_id" integer NOT NULL,
  "location" text,
  "latitude" real,
  "longitude" real,
  "venue" text NOT NULL,
  "description" text NOT NULL,
  "start_date" timestamptz DEFAULT (now()) NOT NULL,
  "canceled" boolean NOT NULL,
  "published" boolean NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "instructors_course_idx_instructor_id" on "instructors_course" ("instructor_id");
CREATE INDEX "instructor_course_latitude_idx" on "instructors_course" ("latitude");
CREATE INDEX "instructor_course_longitude_idx" on "instructors_course" ("longitude");
CREATE INDEX "instructor_course_instructor_id_idx" on "instructors_course" ("instructor_id");

;
--
-- Table: profile
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
  "latitude" real,
  "longitude" real,
  "instructor_trainer" boolean DEFAULT '0' NOT NULL,
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
ALTER TABLE "audit" ADD CONSTRAINT "audit_fk_course_id" FOREIGN KEY ("course_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "audit" ADD CONSTRAINT "audit_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "course" ADD CONSTRAINT "course_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "instructors_course" ADD CONSTRAINT "instructors_course_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "profile" ADD CONSTRAINT "profile_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") ON DELETE CASCADE DEFERRABLE;

;
