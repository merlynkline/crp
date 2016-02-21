-- Create qualification records for existing instructors_course records

;
BEGIN;

    UPDATE  instructors_course 
    SET     qualification_id = (SELECT id FROM qualification WHERE abbreviation = 'TCRP Instructor')
    ;

COMMIT;

