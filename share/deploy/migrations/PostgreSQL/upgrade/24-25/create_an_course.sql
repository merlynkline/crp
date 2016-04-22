-- Create new AN course record

;
BEGIN;

    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id)
    VALUES
    (
        'The Children''s Reflexology Programme for Additional Needs',
        'TCRP-AN',
        'TCRPAN',
        (SELECT id FROM qualification WHERE code = 'TCRP-AN')
    )
    ;

COMMIT;

