-- Convert schema 'share/deploy/migrations/_source/deploy/32/001-auto.yml' to 'share/deploy/migrations/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE olc_component DROP COLUMN notes;

;
ALTER TABLE olc_component DROP COLUMN title;

;
ALTER TABLE olc_component ADD COLUMN olc_page_id integer NOT NULL;

;
ALTER TABLE olc_component ADD COLUMN build_order integer;

;
CREATE INDEX olc_component_idx_olc_page_id on olc_component (olc_page_id);

;
CREATE INDEX olc_component_olc_page_id_idx on olc_component (olc_page_id);

;
ALTER TABLE olc_component ADD CONSTRAINT olc_component_fk_olc_page_id FOREIGN KEY (olc_page_id)
  REFERENCES olc_page (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
DROP TABLE olc_page_component_link CASCADE;

;

COMMIT;

