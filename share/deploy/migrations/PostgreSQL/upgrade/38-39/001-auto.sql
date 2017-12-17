-- Convert schema 'share/deploy/migrations/_source/deploy/38/001-auto.yml' to 'share/deploy/migrations/_source/deploy/39/001-auto.yml':;

;
BEGIN;

;
-- DROP TABLE "olc_student";
CREATE TABLE "olc_student" (
  "id" serial NOT NULL,
  "id_type" text NOT NULL,
  "id_foreign_key" text NOT NULL,
  "course_id" integer NOT NULL,
  "status" text NOT NULL,
  "start_date" timestamptz,
  "last_access_date" timestamptz,
  "completion_date" timestamptz,
  "progress" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "olc_student_idx_course_id" on "olc_student" ("course_id");
CREATE INDEX "student_identity_idx" on "olc_student" ("id_type", "id_foreign_key");

;
ALTER TABLE "olc_student" ADD CONSTRAINT "olc_student_fk_course_id" FOREIGN KEY ("course_id")
  REFERENCES "olc_course" ("id") DEFERRABLE;

;
-- ALTER TABLE olc_course DROP CONSTRAINT olc_course_fk_landing_olc_page_id;

;
-- DROP INDEX olc_course_idx_landing_olc_page_id;

;
-- ALTER TABLE olc_module DROP CONSTRAINT olc_module_fk_landing_olc_page_id;

;
-- DROP INDEX olc_module_idx_landing_olc_page_id;

;

COMMIT;

