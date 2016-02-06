-- Convert schema 'share/deploy/migrations/_source/deploy/19/001-auto.yml' to 'share/deploy/migrations/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "course_type" (
  "id" serial NOT NULL,
  "description" text,
  "abbreviation" text NOT NULL,
  "qualification_required_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "course_type_idx_qualification_required_id" on "course_type" ("qualification_required_id");
CREATE INDEX "qualification_qualification_required_id_idx" on "course_type" ("qualification_required_id");

;
ALTER TABLE "course_type" ADD CONSTRAINT "course_type_fk_qualification_required_id" FOREIGN KEY ("qualification_required_id")
  REFERENCES "qualification" ("id") DEFERRABLE;

;
ALTER TABLE course ADD COLUMN course_type_id integer;

;
CREATE INDEX course_idx_course_type_id on course (course_type_id);

;
ALTER TABLE course ADD CONSTRAINT course_fk_course_type_id FOREIGN KEY (course_type_id)
  REFERENCES course_type (id) DEFERRABLE;

;

COMMIT;

