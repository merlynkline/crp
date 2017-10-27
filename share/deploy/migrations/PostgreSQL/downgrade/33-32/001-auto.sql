-- Convert schema 'share/deploy/migrations/_source/deploy/33/001-auto.yml' to 'share/deploy/migrations/_source/deploy/32/001-auto.yml':;

;
BEGIN;

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
ALTER TABLE "olc_page_component_link" ADD CONSTRAINT "olc_page_component_link_fk_olc_component_id" FOREIGN KEY ("olc_component_id")
  REFERENCES "olc_component" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "olc_page_component_link" ADD CONSTRAINT "olc_page_component_link_fk_olc_page_id" FOREIGN KEY ("olc_page_id")
  REFERENCES "olc_page" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE olc_component DROP CONSTRAINT olc_component_fk_olc_page_id;

;
DROP INDEX olc_component_idx_olc_page_id;

;
DROP INDEX olc_component_olc_page_id_idx;

;
ALTER TABLE olc_component DROP COLUMN olc_page_id;

;
ALTER TABLE olc_component DROP COLUMN build_order;

;
ALTER TABLE olc_component ADD COLUMN notes text;

;
ALTER TABLE olc_component ADD COLUMN title text;

;

COMMIT;

