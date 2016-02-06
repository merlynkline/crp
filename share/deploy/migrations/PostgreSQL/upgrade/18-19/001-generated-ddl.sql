-- Convert schema 'share/deploy/migrations/_source/deploy/18/001-auto.yml' to 'share/deploy/migrations/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "instructor_qualification" (
  "id" serial NOT NULL,
  "qualification_id" integer NOT NULL,
  "instructor_id" integer NOT NULL,
  "passed_date" timestamptz,
  PRIMARY KEY ("id")
);
CREATE INDEX "instructor_qualification_idx_instructor_id" on "instructor_qualification" ("instructor_id");
CREATE INDEX "instructor_qualification_idx_qualification_id" on "instructor_qualification" ("qualification_id");
CREATE INDEX "qualification_qualification_id_idx" on "instructor_qualification" ("qualification_id");
CREATE INDEX "qualification_instructor_id_idx" on "instructor_qualification" ("instructor_id");

;
CREATE TABLE "qualification" (
  "id" serial NOT NULL,
  "qualification" text,
  "abbreviation" text NOT NULL,
  PRIMARY KEY ("id")
);

;
ALTER TABLE "instructor_qualification" ADD CONSTRAINT "instructor_qualification_fk_instructor_id" FOREIGN KEY ("instructor_id")
  REFERENCES "login" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "instructor_qualification" ADD CONSTRAINT "instructor_qualification_fk_qualification_id" FOREIGN KEY ("qualification_id")
  REFERENCES "qualification" ("id") DEFERRABLE;

;

COMMIT;

