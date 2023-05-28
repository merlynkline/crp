-- Create new online instructor qualification records

;
BEGIN;

    INSERT INTO qualification
    (code, qualification, abbreviation)
    VALUES
    ('TCRP-OL', 'Instructor in The Children''s Reflexology Programme (online)', 'TCRP Instructor (online)')
    ;

    INSERT INTO qualification
    (code, qualification, abbreviation)
    VALUES
    ('TCRP-AN-OL', 'Additional Needs Instructor in The Children''s Reflexology Programme (online)', 'TCRP AN Instructor (online)')
    ;

    INSERT INTO qualification
    (code, qualification, abbreviation)
    VALUES
    ('TCRP-TA-OL', 'Instructor in The Children''s Reflexology Programme for Teenagers (online)', 'TCRP Instructor Teenagers (online)')
    ;

COMMIT;

