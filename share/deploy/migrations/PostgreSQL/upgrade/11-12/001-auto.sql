-- Convert schema 'share/deploy/migrations/_source/deploy/11/001-auto.yml' to 'share/deploy/migrations/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "instructors_course" (
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
  "canceled" boolean NOT NULL,
  "published" boolean NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "instructors_course_idx_instructor_id" on "instructors_course" ("instructor_id");
CREATE INDEX "instructor_course_latitude_idx" on "instructors_course" ("latitude");
CREATE INDEX "instructor_course_longitude_idx" on "instructors_course" ("longitude");
CREATE INDEX "instructor_course_instructor_id_idx" on "instructors_course" ("instructor_id");

;
ALTER TABLE "instructors_course" ADD CONSTRAINT "instructors_course_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") DEFERRABLE;

;
ALTER TABLE login DROP CONSTRAINT login_fk_id;

;
ALTER TABLE profile DROP CONSTRAINT profile_fk_instructor_id;

;
ALTER TABLE profile ADD COLUMN instructor_trainer boolean DEFAULT '0' NOT NULL;

;
ALTER TABLE profile ADD CONSTRAINT profile_fk_instructor_id FOREIGN KEY (instructor_id)
  REFERENCES login (id) ON DELETE CASCADE DEFERRABLE;

;

COMMIT;

