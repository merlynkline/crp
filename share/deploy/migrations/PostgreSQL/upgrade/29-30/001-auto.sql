-- Convert schema 'share/deploy/migrations/_source/deploy/29/001-auto.yml' to 'share/deploy/migrations/_source/deploy/30/001-auto.yml':;

;
BEGIN;

;
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
ALTER TABLE "professional" ADD CONSTRAINT "professional_fk_instructors_course_id" FOREIGN KEY ("instructors_course_id")
  REFERENCES "instructors_course" ("id") DEFERRABLE;

;
ALTER TABLE course_type ADD COLUMN is_professional boolean DEFAULT 'f' NOT NULL;

;

COMMIT;

