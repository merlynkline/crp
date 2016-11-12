-- Drop pro qual records

;
BEGIN;

    DELETE FROM qualification WHERE code IN ('TCRP-AN-PRO', 'TCRP-EY-PRO');
    DELETE FROM course_type   WHERE code IN ('TCRPANPRO',   'TCRPEYPRO');

COMMIT;

