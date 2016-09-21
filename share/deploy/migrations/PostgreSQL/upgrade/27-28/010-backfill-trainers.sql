-- Backfill the new instructor_qualification.trainer_id column

update instructor_qualification
set    trainer_id = (
    select  id
    from    login
    where   email = 'sue@susanquayle.co.uk'
);
