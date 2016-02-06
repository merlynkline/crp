-- Create qualification records for existing instructors

;
BEGIN;

    INSERT INTO qualification
    (qualification, abbreviation)
    VALUES
    ('Instructor in The Children''s Reflexology Programme', 'TCRP Instructor')
    ;


    INSERT INTO instructor_qualification
    (qualification_id, instructor_id, passed_date)
    (
        SELECT  (SELECT id FROM qualification WHERE abbreviation = 'TCRP Instructor') AS qualification_id
        ,       id
        ,       create_date
        FROM    login
    )
    ;

COMMIT;

