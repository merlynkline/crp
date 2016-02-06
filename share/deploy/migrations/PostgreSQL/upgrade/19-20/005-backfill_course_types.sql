-- Create qualification records for existing instructors

;
BEGIN;

    INSERT INTO course_type
    (description, abbreviation, qualification_required_id)
    VALUES
    (
        'The Children''s Reflexology Programme',
        'TCRP',
        (SELECT id FROM qualification WHERE abbreviation = 'TCRP Instructor')
    )
    ;


    UPDATE  course 
    SET     course_type_id = (SELECT id FROM course_type WHERE abbreviation = 'TCRP')
    ;

COMMIT;

