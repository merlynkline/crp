-- Create new AN  and reflex qualification records

;
BEGIN;

    INSERT INTO qualification
    (code, qualification, abbreviation)
    VALUES
    ('TCRP-AN', 'Additional Needs Instructor in The Children''s Reflexology Programme', 'TCRP AN Instructor')
    ;

    INSERT INTO qualification
    (code, qualification, abbreviation)
    VALUES
    ('TCRP-REFLEX', 'Reflexologist Instructor in The Children''s Reflexology Programme', 'TCRP Reflex Instructor')
    ;

    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id)
    VALUES
    (
        'The Children''s Reflexology Programme',
        'TCRP',
        'TCRPRX',
        (SELECT id FROM qualification WHERE code = 'TCRP-REFLEX')
    )
    ;

COMMIT;

