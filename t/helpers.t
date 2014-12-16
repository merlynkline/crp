use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('CRP');
my $c = $t->app->build_controller;
my $mode = $c->app->mode;

my $crp_helper = $c->crp;

# stash_list
is_deeply($crp_helper->stash_list('test_list'), [], 'stash_list no value');
$c->stash('test_list' => 'one');
is_deeply($crp_helper->stash_list('test_list'), ['one'], 'stash_list one value');
$c->stash('test_list' => ['one', 'two']);
is_deeply($crp_helper->stash_list('test_list'), ['one', 'two'], 'stash_list two values');

# email_decorated
my $model = $crp_helper->model('Login');
can_ok($model, 'find');
is($crp_helper->email_decorated('test@example.com'), 'test@example.com');
is($crp_helper->email_decorated('test@example.com', 'tester'), 'tester <test@example.com>');

# email_to
my $test_email = $c->app->config->{test}->{email};
is($crp_helper->email_to('test@example.com'), " (Was to: test\@example.com) <$test_email>");
is($crp_helper->email_to('test@example.com', 'tester'), "tester (Was to: test\@example.com) <$test_email>");
$c->app->mode('production');
is($crp_helper->email_to('test@example.com'), 'test@example.com');
is($crp_helper->email_to('test@example.com', 'tester'), 'tester <test@example.com>');
$c->app->mode($mode);

# trimmed_param
foreach my $value (
    'value  value',
    ' value  value',
    'value  value   ',
    '  value  value  ',
    "\tvalue  value",
) {
    $c->param('test', $value);
    is($crp_helper->trimmed_param('test'), 'value  value', "trimmed_parami for '$value'");
}
$c->param('test', undef);
is($crp_helper->trimmed_param('test'), undef, "trimmed_parami for undef");

# Path to public file
is($crp_helper->path_for_public_file("test/test"), $c->app->home->rel_file("public/test/test"), "public file path");

# Instructor photo file location within public files
my $instructor_photo_path = '/images/Instructors/photos/';
is($crp_helper->instructor_photo_location, $instructor_photo_path, 'Instructor photo file location');

foreach my $fixture (
    [      1, '161-their-small-green-boys-bonnet.jpg'],
    [      0, '168-my-cute-silver-childs-bib.jpg'],
    [ 987654, '197-your-small-olive-newborn-hat.jpg'],
    [     11, '53-their-charming-lime-boys-bib.jpg'],
) {
    # Name of an instructor's photo file
    is($crp_helper->name_for_instructor_photo($fixture->[0]), $fixture->[1], "Instructors photo name #$fixture->[0]");
    # Instructor photo file path
    is($crp_helper->path_for_instructor_photo($fixture->[0]),
        $c->app->home->rel_file("/public$instructor_photo_path/$fixture->[1]"),
        "Instructor photo file path #$fixture->[0]"
    );
}

# Date format
foreach my $fixture (
    ['2014-01-01',  'csv',      '01Jan2014'],
    ['2014-01-31',  'csv',      '31Jan2014'],
    ['2014-06-30',  'csv',      '30Jun2014'],
    ['2014-01-01',  'short',    '01-Jan-2014'],
    ['2014-01-31',  'short',    '31-Jan-2014'],
    ['2014-06-30',  'short',    '30-Jun-2014'],
) {
    my($y, $m, $d) = split '-', $fixture->[0];
    my $result = $crp_helper->format_date(DateTime->new(year => $y, month => $m, day => $d), $fixture->[1]);
    is($result, $fixture->[2], "format_date $fixture->[0] $fixture->[1]");
}



done_testing();
