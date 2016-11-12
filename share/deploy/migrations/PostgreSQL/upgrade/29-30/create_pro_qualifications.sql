-- Create pro qual records

;
BEGIN;

    INSERT INTO qualification
    (code, qualification, abbreviation)
    VALUES
    ('TCRP-AN-PRO', 'Additional Needs Professional Instructor in The Children''s Reflexology Programme', 'TCRP AN PRO Instructor')
    ;

    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id)
    VALUES
    (
        'The Children''s Reflexology Programme Additional Needs Professional',
        'TCRP-AN-PRO',
        'TCRPANPRO',
        (SELECT id FROM qualification WHERE code = 'TCRP-AN-PRO')
    )
    ;


    INSERT INTO qualification
    (code, qualification, abbreviation)
    VALUES
    ('TCRP-EY-PRO', 'Early Years Professional Instructor in The Children''s Reflexology Programme', 'TCRP EY PRO Instructor')
    ;

    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id)
    VALUES
    (
        'The Children''s Reflexology Programme Early Years Professional',
        'TCRP-EY-PRO',
        'TCRPEYPRO',
        (SELECT id FROM qualification WHERE code = 'TCRP-EY-PRO')
    )
    ;

COMMIT;

