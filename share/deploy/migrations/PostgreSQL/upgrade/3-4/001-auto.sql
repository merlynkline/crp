-- Convert schema 'share/deploy/migrations/_source/deploy/3/001-auto.yml' to 'share/deploy/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE enquiry ALTER COLUMN create_date TYPE timestamptz;

;
ALTER TABLE enquiry ALTER COLUMN create_date SET DEFAULT (now());

;
ALTER TABLE enquiry ALTER COLUMN suspend_date TYPE timestamptz;

;
ALTER TABLE login ALTER COLUMN create_date TYPE timestamptz;

;
ALTER TABLE login ALTER COLUMN create_date SET DEFAULT (now());

;
ALTER TABLE login ALTER COLUMN last_login_date TYPE timestamptz;

;
ALTER TABLE login ALTER COLUMN otp_expiry_date TYPE timestamptz;

;

COMMIT;

