-- Convert schema 'share/deploy/migrations/_source/deploy/2/001-auto.yml' to 'share/deploy/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
DROP INDEX enquiry_suspend_date_idx;

;
DROP INDEX enquiry_latitude_idx;

;
DROP INDEX enquiry_longitude_idx;

;

COMMIT;

