-- Convert schema 'share/deploy/migrations/_source/deploy/31/001-auto.yml' to 'share/deploy/migrations/_source/deploy/30/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE professional DROP CONSTRAINT professional_fk_instructors_course_id;

;
ALTER TABLE professional ADD CONSTRAINT professional_fk_instructors_course_id FOREIGN KEY (instructors_course_id)
  REFERENCES instructors_course (id) DEFERRABLE;

;
DROP TABLE olc_Component CASCADE;

;
DROP TABLE olc_page CASCADE;

;
DROP TABLE olc_course CASCADE;

;
DROP TABLE olc_module CASCADE;

;
DROP TABLE olc_module_page_link CASCADE;

;
DROP TABLE olc_page_component_link CASCADE;

;
DROP TABLE olc_course_module_link CASCADE;

;

COMMIT;

