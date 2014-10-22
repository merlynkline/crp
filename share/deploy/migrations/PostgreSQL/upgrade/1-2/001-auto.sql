-- Convert schema 'share/deploy/migrations/_source/deploy/1/001-auto.yml' to 'share/deploy/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE INDEX enquiry_suspend_date_idx on enquiry (suspend_date);

;
CREATE INDEX enquiry_latitude_idx on enquiry (latitude);

;
CREATE INDEX enquiry_longitude_idx on enquiry (longitude);

;

COMMIT;

