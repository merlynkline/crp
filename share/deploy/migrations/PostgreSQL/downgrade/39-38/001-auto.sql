-- Convert schema 'share/deploy/migrations/_source/deploy/39/001-auto.yml' to 'share/deploy/migrations/_source/deploy/38/001-auto.yml':;

;
BEGIN;

;
CREATE INDEX olc_course_idx_landing_olc_page_id on olc_course (landing_olc_page_id);

;
ALTER TABLE olc_course ADD CONSTRAINT olc_course_fk_landing_olc_page_id FOREIGN KEY (landing_olc_page_id)
  REFERENCES olc_page (id) DEFERRABLE;

;
CREATE INDEX olc_module_idx_landing_olc_page_id on olc_module (landing_olc_page_id);

;
ALTER TABLE olc_module ADD CONSTRAINT olc_module_fk_landing_olc_page_id FOREIGN KEY (landing_olc_page_id)
  REFERENCES olc_page (id) DEFERRABLE;

;
DROP TABLE olc_student CASCADE;

;

COMMIT;

