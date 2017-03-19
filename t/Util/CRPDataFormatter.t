use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Deep;
use Mock::Quick;

use CRP::Util::CRPDataFormatter;

use DateTime;

my $year = DateTime->now()->year;
my $expected = DateTime->new(year => $year, month => 1, day => 1);

my $signup_date = DateTime->new(year => $year, month => 1, day => 1);
is(CRP::Util::CRPDataFormatter::_certificate_date($signup_date), $expected, '_certificate_date: this year');

$signup_date = DateTime->new(year => $year - 1, month => 1, day => 1);
is(CRP::Util::CRPDataFormatter::_certificate_date($signup_date), $expected, '_certificate_date: last year');

$signup_date = DateTime->new(year => $year - 10, month => 1, day => 1);
is(CRP::Util::CRPDataFormatter::_certificate_date($signup_date), $expected, '_certificate_date: last decade');

my $login = qobj (
    create_date => DateTime->new(year => 2010, month => 1, day => 1),
    email       => 'EMAIL',
);

my $t = Test::Mojo->new('CRP');
my $c = $t->app->build_controller;

my $profile = qobj (
    name        => 'NAME',
    telephone   => 'TELEPHONE',
    mobile      => 'MOBILE',
    postcode    => "POSTCODE",
    address     => "  ADR1  \r\n\n  ADR2  ",
    login       => $login,
    web_page_slug => 'sluggo',
);

my $data = {
    profile     => $profile,
    email       => 'EMAIL',
};

$expected = {
    email       => 'EMAIL',
    name        => 'NAME',
    telephone   => 'TELEPHONE',
    mobile      => 'MOBILE',
    postcode    => "POSTCODE",
    signature   => '-52560160',
    one_line_address    => "ADR1, ADR2",
    phone_numbers       => "TELEPHONE / MOBILE",
    profile_image       => $c->crp->path_for_public_file('images/Instructors/photos/default.jpg'),
    status              => 'TRAINEE',
};

my $formatted = CRP::Util::CRPDataFormatter::format_data($c, $data);
cmp_deeply($formatted, superhashof($expected), "_extract_crp_data [1]");

$profile->telephone(undef);
$expected->{telephone} = undef;
$expected->{phone_numbers} = 'MOBILE';
$formatted = CRP::Util::CRPDataFormatter::format_data($c, $data);
cmp_deeply($formatted, superhashof($expected), "_extract_crp_data [2:mobile only]");

$profile->telephone('TELEPHONE');
$profile->mobile(undef);
$expected->{telephone} = 'TELEPHONE';
$expected->{phone_numbers} = 'TELEPHONE';
$expected->{mobile} = undef;
$formatted = CRP::Util::CRPDataFormatter::format_data($c, $data);
cmp_deeply($formatted, superhashof($expected), "_extract_crp_data [2:telephone only]");

done_testing();

