-- Set up instructor trainer courses

;
BEGIN;

    -- New qualifications for Instructor Trainers

    INSERT INTO qualification
    (code, qualification, abbreviation)
    VALUES
    ('INST-TRAIN', 'Instructor Trainer in The Children''s Reflexology Programme', 'TCRP Instructor Trainer')
    ;

    INSERT INTO qualification
    (code, qualification, abbreviation)
    VALUES
    ('INST-TRAIN-AN', 'Additional Needs Instructor Trainer in The Children''s Reflexology Programme', 'TCRP AN Instructor Trainer')
    ;



    -- New course types for Instructor Trainer courses

    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id, qualification_earned_id)
    VALUES
    (
        'Instructor in The Children''s Reflexology Programme',
        'TCRP Instructor',
        'TCRPINST',
        (SELECT id FROM qualification WHERE code = 'INST-TRAIN'),
        (SELECT id FROM qualification WHERE code = 'TCRP')
    )
    ;

    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id, qualification_earned_id)
    VALUES
    (
        'Additional Needs Instructor in The Children''s Reflexology Programme',
        'TCRP AN Instructor',
        'TCRPANINST',
        (SELECT id FROM qualification WHERE code = 'INST-TRAIN-AN'),
        (SELECT id FROM qualification WHERE code = 'TCRP-AN')
    )
    ;


    INSERT INTO course_type
    (description, abbreviation, code, qualification_required_id, qualification_earned_id)
    VALUES
    (
        'Reflexologist Instructor in The Children''s Reflexology Programme',
        'TCRP Reflex Instructor',
        'TCRPREFLEXINST',
        (SELECT id FROM qualification WHERE code = 'INST-TRAIN'),
        (SELECT id FROM qualification WHERE code = 'TCRP-REFLEX')
    )
    ;



    -- Backfill new columns in instructors_course table

    UPDATE instructors_course
    SET course_type_id = (SELECT id FROM course_type WHERE qualification_earned_id = instructors_course.qualification_id)
    ;

    UPDATE instructors_course
    SET duration = '3 days'
    ;

;

COMMIT;


