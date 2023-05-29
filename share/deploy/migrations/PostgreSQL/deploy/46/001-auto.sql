-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon May 29 14:14:20 2023
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
  "is_demo" boolean,
  "auto_login" boolean,
  "disabled_date" timestamptz,
  PRIMARY KEY ("id"),
  CONSTRAINT "login_email_key" UNIQUE ("email")
);

;
--
-- Table: olc_course
--
CREATE TABLE "olc_course" (
  "id" serial NOT NULL,
  "name" text,
  "notes" text,
  "description" text,
  "title" text,
  "guid" text,
  "last_update_date" timestamptz,
  "code" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "olc_course_guid_idx" on "olc_course" ("guid");
CREATE INDEX "olc_course_code_idx" on "olc_course" ("code");

;
--
-- Table: olc_module
--
CREATE TABLE "olc_module" (
  "id" serial NOT NULL,
  "name" text,
  "notes" text,
  "description" text,
  "title" text,
  "guid" text,
  "last_update_date" timestamptz,
  PRIMARY KEY ("id")
);
CREATE INDEX "olc_module_guid_idx" on "olc_module" ("guid");

;
--
-- Table: olc_page
--
CREATE TABLE "olc_page" (
  "id" serial NOT NULL,
  "name" text,
  "notes" text,
  "description" text,
  "title" text,
  "guid" text,
  "last_update_date" timestamptz,
  PRIMARY KEY ("id")
);
CREATE INDEX "olc_page_guid_idx" on "olc_page" ("guid");

;
--
-- Table: premium_authorisation
--
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
--
-- Table: qualification
--
CREATE TABLE "qualification" (
  "id" serial NOT NULL,
  "qualification" text,
  "abbreviation" text NOT NULL,
  "code" text,
  "olccodes" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "qualification_code_idx" on "qualification" ("code");

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
-- Table: course_type
--
CREATE TABLE "course_type" (
  "id" serial NOT NULL,
  "description" text,
  "abbreviation" text NOT NULL,
  "qualification_required_id" integer NOT NULL,
  "code" text,
  "qualification_earned_id" integer,
  "is_professional" boolean DEFAULT 'f' NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "course_type_idx_qualification_earned_id" on "course_type" ("qualification_earned_id");
CREATE INDEX "course_type_idx_qualification_required_id" on "course_type" ("qualification_required_id");
CREATE INDEX "course_type_qualification_required_id_idx" on "course_type" ("qualification_required_id");
CREATE INDEX "course_type_code_idx" on "course_type" ("code");

;
--
-- Table: olc_component
--
CREATE TABLE "olc_component" (
  "id" serial NOT NULL,
  "olc_page_id" integer NOT NULL,
  "build_order" integer,
  "name" text,
  "type" text NOT NULL,
  "data_version" integer,
  "data" text,
  "guid" text,
  "last_update_date" timestamptz,
  PRIMARY KEY ("id")
);
CREATE INDEX "olc_component_idx_olc_page_id" on "olc_component" ("olc_page_id");
CREATE INDEX "olc_component_olc_page_id_idx" on "olc_component" ("olc_page_id");
CREATE INDEX "olc_component_guid_idx" on "olc_component" ("guid");

;
--
-- Table: olc_student
--
CREATE TABLE "olc_student" (
  "id" serial NOT NULL,
  "id_type" text NOT NULL,
  "id_foreign_key" text NOT NULL,
  "course_id" integer NOT NULL,
  "status" text NOT NULL,
  "start_date" timestamptz,
  "last_access_date" timestamptz,
  "completion_date" timestamptz,
  "name" text NOT NULL,
  "email" text NOT NULL,
  "progress" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "olc_student_idx_course_id" on "olc_student" ("course_id");
CREATE INDEX "student_identity_idx" on "olc_student" ("course_id", "id_type", "id_foreign_key");
CREATE INDEX "olc_student_status_idx" on "olc_student" ("status");

;
--
-- Table: premium_cookie_log
--
CREATE TABLE "premium_cookie_log" (
  "id" serial NOT NULL,
  "timestamp" timestamptz DEFAULT (now()) NOT NULL,
  "auth_id" integer NOT NULL,
  "remote_id" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "premium_cookie_log_idx_auth_id" on "premium_cookie_log" ("auth_id");

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
  "hide_address" boolean DEFAULT 'f' NOT NULL,
  PRIMARY KEY ("instructor_id"),
  CONSTRAINT "web_page_slug_key" UNIQUE ("web_page_slug")
);
CREATE INDEX "profile_web_page_slug_idx" on "profile" ("web_page_slug");
CREATE INDEX "profile_latitude_idx" on "profile" ("latitude");
CREATE INDEX "profile_longitude_idx" on "profile" ("longitude");

;
--
-- Table: instructor_qualification
--
CREATE TABLE "instructor_qualification" (
  "id" serial NOT NULL,
  "qualification_id" integer NOT NULL,
  "instructor_id" integer NOT NULL,
  "passed_date" timestamptz,
  "trainer_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "instructor_qualification_idx_instructor_id" on "instructor_qualification" ("instructor_id");
CREATE INDEX "instructor_qualification_idx_qualification_id" on "instructor_qualification" ("qualification_id");
CREATE INDEX "instructor_qualification_idx_trainer_id" on "instructor_qualification" ("trainer_id");
CREATE INDEX "qualification_qualification_id_idx" on "instructor_qualification" ("qualification_id");
CREATE INDEX "qualification_instructor_id_idx" on "instructor_qualification" ("instructor_id");

;
--
-- Table: olc_course_module_link
--
CREATE TABLE "olc_course_module_link" (
  "olc_course_id" integer NOT NULL,
  "olc_module_id" integer NOT NULL,
  "order" integer,
  PRIMARY KEY ("olc_course_id", "olc_module_id")
);
CREATE INDEX "olc_course_module_link_idx_olc_course_id" on "olc_course_module_link" ("olc_course_id");
CREATE INDEX "olc_course_module_link_idx_olc_module_id" on "olc_course_module_link" ("olc_module_id");

;
--
-- Table: olc_module_page_link
--
CREATE TABLE "olc_module_page_link" (
  "olc_module_id" integer NOT NULL,
  "olc_page_id" integer NOT NULL,
  "order" integer,
  PRIMARY KEY ("olc_module_id", "olc_page_id")
);
CREATE INDEX "olc_module_page_link_idx_olc_module_id" on "olc_module_page_link" ("olc_module_id");
CREATE INDEX "olc_module_page_link_idx_olc_page_id" on "olc_module_page_link" ("olc_page_id");

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
  "book_excluded" boolean DEFAULT 'f' NOT NULL,
  "course_type_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "course_idx_course_type_id" on "course" ("course_type_id");
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
  "price" text NOT NULL,
  "canceled" boolean NOT NULL,
  "published" boolean NOT NULL,
  "course_type_id" integer,
  "duration" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "instructors_course_idx_course_type_id" on "instructors_course" ("course_type_id");
CREATE INDEX "instructors_course_idx_instructor_id" on "instructors_course" ("instructor_id");
CREATE INDEX "instructor_course_latitude_idx" on "instructors_course" ("latitude");
CREATE INDEX "instructor_course_longitude_idx" on "instructors_course" ("longitude");
CREATE INDEX "instructor_course_instructor_id_idx" on "instructors_course" ("instructor_id");

;
--
-- Table: professional
--
CREATE TABLE "professional" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "organisation_name" text NOT NULL,
  "organisation_address" text,
  "organisation_postcode" text,
  "organisation_telephone" text,
  "email" text NOT NULL,
  "instructors_course_id" integer NOT NULL,
  "is_suspended" boolean DEFAULT 'f' NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "professional_idx_instructors_course_id" on "professional" ("instructors_course_id");
CREATE INDEX "professional_email_idx" on "professional" ("email");
CREATE INDEX "professional_name_idx" on "professional" ("name");

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
ALTER TABLE "course_type" ADD CONSTRAINT "course_type_fk_qualification_earned_id" FOREIGN KEY ("qualification_earned_id")
  REFERENCES "qualification" ("id") DEFERRABLE;

;
ALTER TABLE "course_type" ADD CONSTRAINT "course_type_fk_qualification_required_id" FOREIGN KEY ("qualification_required_id")
  REFERENCES "qualification" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_component" ADD CONSTRAINT "olc_component_fk_olc_page_id" FOREIGN KEY ("olc_page_id")
  REFERENCES "olc_page" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_student" ADD CONSTRAINT "olc_student_fk_course_id" FOREIGN KEY ("course_id")
  REFERENCES "olc_course" ("id") DEFERRABLE;

;
ALTER TABLE "premium_cookie_log" ADD CONSTRAINT "premium_cookie_log_fk_auth_id" FOREIGN KEY ("auth_id")
  REFERENCES "premium_authorisation" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "profile" ADD CONSTRAINT "profile_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "instructor_qualification" ADD CONSTRAINT "instructor_qualification_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "instructor_qualification" ADD CONSTRAINT "instructor_qualification_fk_qualification_id" FOREIGN KEY ("qualification_id")
  REFERENCES "qualification" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "instructor_qualification" ADD CONSTRAINT "instructor_qualification_fk_trainer_id" FOREIGN KEY ("trainer_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "olc_course_module_link" ADD CONSTRAINT "olc_course_module_link_fk_olc_course_id" FOREIGN KEY ("olc_course_id")
  REFERENCES "olc_course" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_course_module_link" ADD CONSTRAINT "olc_course_module_link_fk_olc_module_id" FOREIGN KEY ("olc_module_id")
  REFERENCES "olc_module" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_module_page_link" ADD CONSTRAINT "olc_module_page_link_fk_olc_module_id" FOREIGN KEY ("olc_module_id")
  REFERENCES "olc_module" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_module_page_link" ADD CONSTRAINT "olc_module_page_link_fk_olc_page_id" FOREIGN KEY ("olc_page_id")
  REFERENCES "olc_page" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "course" ADD CONSTRAINT "course_fk_course_type_id" FOREIGN KEY ("course_type_id")
  REFERENCES "course_type" ("id") DEFERRABLE;

;
ALTER TABLE "course" ADD CONSTRAINT "course_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "instructors_course" ADD CONSTRAINT "instructors_course_fk_course_type_id" FOREIGN KEY ("course_type_id")
  REFERENCES "course_type" ("id") DEFERRABLE;

;
ALTER TABLE "instructors_course" ADD CONSTRAINT "instructors_course_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "professional" ADD CONSTRAINT "professional_fk_instructors_course_id" FOREIGN KEY ("instructors_course_id")
  REFERENCES "instructors_course" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
