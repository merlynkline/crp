#

{
    schema_class    => 'CRP::Model::Schema',
    resultsets      => [qw(Enquiry)],
    fixture_sets => {
        basic => [
            Enquiry => [
                [qw(
                    id name email create_date suspend_date
                    location latitude longitude
                    notify_new_courses notify_tutors send_newsletter
                )],
                [
                    1, 'Mary', 'mary@example.com', '2014-10-05', '2014-10-05',
                    'London', -0.13, 51.5,
                    1, 1, 1,
                ],
                [
                    2, 'Jane', 'jane@example.com', '2014-10-06', '',
                    'Cardiff', -3.18, 51.48,
                    1, 0, 1,
                ],
                [
                    3, 'Fred', 'fred@examle.com', '2014-10-07', '',
                    '', '', '',
                    1, 0, 0,
                ],
            ],
        ],
    },
};

