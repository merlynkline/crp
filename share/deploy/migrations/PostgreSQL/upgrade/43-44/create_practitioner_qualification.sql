-- Create new online practioner qualification records

;
BEGIN;

    INSERT INTO qualification
    (code, qualification, abbreviation, olccodes)
    VALUES
    ('TCRP-OLC-PRACT', 'Children''s Reflexology Programme Child Reflexology Practioner Online', 'TCRP Online Practitioner', 'PC4Reflexes')
    ;

COMMIT;


