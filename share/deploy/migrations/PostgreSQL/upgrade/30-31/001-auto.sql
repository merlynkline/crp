-- Convert schema 'share/deploy/migrations/_source/deploy/30/001-auto.yml' to 'share/deploy/migrations/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "olc_component" (
  "id" serial NOT NULL,
  "name" text,
  "description" text,
  "title" text,
  "type" text NOT NULL,
  "data_version" integer NOT NULL,
  "data" text,
  PRIMARY KEY ("id")
);

;
CREATE TABLE "olc_course" (
  "id" serial NOT NULL,
  "name" text,
  "description" text,
  "title" text,
  "landing_olc_page_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "olc_course_idx_landing_olc_page_id" on "olc_course" ("landing_olc_page_id");

;
CREATE TABLE "olc_course_module_link" (
  "olc_course_id" integer NOT NULL,
  "olc_module_id" integer NOT NULL,
  "order" integer,
  PRIMARY KEY ("olc_course_id", "olc_module_id")
);
CREATE INDEX "olc_course_module_link_idx_olc_course_id" on "olc_course_module_link" ("olc_course_id");
CREATE INDEX "olc_course_module_link_idx_olc_module_id" on "olc_course_module_link" ("olc_module_id");

;
CREATE TABLE "olc_module" (
  "id" serial NOT NULL,
  "name" text,
  "description" text,
  "title" text,
  "landing_olc_page_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "olc_module_idx_landing_olc_page_id" on "olc_module" ("landing_olc_page_id");

;
CREATE TABLE "olc_module_page_link" (
  "olc_module_id" integer NOT NULL,
  "olc_page_id" integer NOT NULL,
  "order" integer,
  PRIMARY KEY ("olc_module_id", "olc_page_id")
);
CREATE INDEX "olc_module_page_link_idx_olc_module_id" on "olc_module_page_link" ("olc_module_id");
CREATE INDEX "olc_module_page_link_idx_olc_page_id" on "olc_module_page_link" ("olc_page_id");

;
CREATE TABLE "olc_page" (
  "id" serial NOT NULL,
  "name" text,
  "description" text,
  "title" text,
  PRIMARY KEY ("id")
);

;
CREATE TABLE "olc_page_component_link" (
  "olc_page_id" integer NOT NULL,
  "olc_component_id" integer NOT NULL,
  "config" text,
  "order" integer,
  PRIMARY KEY ("olc_page_id", "olc_component_id")
);
CREATE INDEX "olc_page_component_link_idx_olc_component_id" on "olc_page_component_link" ("olc_component_id");
CREATE INDEX "olc_page_component_link_idx_olc_page_id" on "olc_page_component_link" ("olc_page_id");

;
ALTER TABLE "olc_course" ADD CONSTRAINT "olc_course_fk_landing_olc_page_id" FOREIGN KEY ("landing_olc_page_id")
  REFERENCES "olc_page" ("id") DEFERRABLE;

;
ALTER TABLE "olc_course_module_link" ADD CONSTRAINT "olc_course_module_link_fk_olc_course_id" FOREIGN KEY ("olc_course_id")
  REFERENCES "olc_course" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_course_module_link" ADD CONSTRAINT "olc_course_module_link_fk_olc_module_id" FOREIGN KEY ("olc_module_id")
  REFERENCES "olc_module" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_module" ADD CONSTRAINT "olc_module_fk_landing_olc_page_id" FOREIGN KEY ("landing_olc_page_id")
  REFERENCES "olc_page" ("id") DEFERRABLE;

;
ALTER TABLE "olc_module_page_link" ADD CONSTRAINT "olc_module_page_link_fk_olc_module_id" FOREIGN KEY ("olc_module_id")
  REFERENCES "olc_module" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_module_page_link" ADD CONSTRAINT "olc_module_page_link_fk_olc_page_id" FOREIGN KEY ("olc_page_id")
  REFERENCES "olc_page" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_page_component_link" ADD CONSTRAINT "olc_page_component_link_fk_olc_component_id" FOREIGN KEY ("olc_component_id")
  REFERENCES "olc_component" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_page_component_link" ADD CONSTRAINT "olc_page_component_link_fk_olc_page_id" FOREIGN KEY ("olc_page_id")
  REFERENCES "olc_page" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE professional DROP CONSTRAINT professional_fk_instructors_course_id;

;
ALTER TABLE professional ADD CONSTRAINT professional_fk_instructors_course_id FOREIGN KEY (instructors_course_id)
  REFERENCES instructors_course (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

