-- Convert schema 'share/deploy/migrations/_source/deploy/10/001-auto.yml' to 'share/deploy/migrations/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
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
CREATE TABLE "course" (
  "id" serial NOT NULL,
  "instructor_id" integer NOT NULL,
  "location" text,
  "latitude" numeric,
  "longitude" numeric,
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
ALTER TABLE "audit" ADD CONSTRAINT "audit_fk_course_id" FOREIGN KEY ("course_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "audit" ADD CONSTRAINT "audit_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE "course" ADD CONSTRAINT "course_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") DEFERRABLE;

;

COMMIT;

