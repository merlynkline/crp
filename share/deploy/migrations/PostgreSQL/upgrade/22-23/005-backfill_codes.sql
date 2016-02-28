-- Create codes for existing course types and qualifications

;
BEGIN;

    UPDATE qualification SET code = 'TCRP' where id = 1;

COMMIT;

BEGIN;

    UPDATE course_type SET code = 'TCRP' where id = 1;

COMMIT;

