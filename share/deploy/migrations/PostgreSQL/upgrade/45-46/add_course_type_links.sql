-- Add course_type links for new online instructor qualification records

;
BEGIN;

    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id)
    VALUES
    (
        'The Children''s Reflexology Programme',
        'TCRP',
        'TCRP',
        (SELECT id FROM qualification WHERE code = 'TCRP-OL')
    )
    ;

    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id)
    VALUES
    (
        'The Children''s Reflexology Programme for Additional Needs',
        'TCRP-AN',
        'TCRPAN',
        (SELECT id FROM qualification WHERE code = 'TCRP-AN-OL')
    )

    ;
    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id)
    VALUES
    (
        'The Children''s Reflexology Programme for Teenagers',
        'TCRP-TA',
        'TCRPTA',
        (SELECT id FROM qualification WHERE code = 'TCRP-TA-OL')
    )
    ;

COMMIT;

