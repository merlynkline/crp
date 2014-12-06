use Test::More;
use Mock::Quick;

use CRP::Util::PDF;

my $data = {A => 'a', B => 'b'};
my $str = 'Variable [% A %], variable [%  B  %]';

is(CRP::Util::PDF::_replace_place_holders($str), 'Variable [[ A ]], variable [[ B ]]', "_replace_place_holders test mode");
is(CRP::Util::PDF::_replace_place_holders($str, $data), 'Variable a, variable b', "_replace_place_holders normal mode");

my $profile = qobj (
    name        => 'NAME',
    telephone   => 'TELEPHONE',
    mobile      => 'MOBILE',
    postcode    => "POSTCODE",
    address     => "  ADR1  \r\n\n  ADR2  ",
);

$data = {
    url         => 'URL',
    email       => 'EMAIL',
    profile     => $profile,
};

my $expected = {
    url         => 'URL',
    email       => 'EMAIL',
    name        => 'NAME',
    telephone   => 'TELEPHONE',
    mobile      => 'MOBILE',
    postcode    => "POSTCODE",
    one_line_address    => "ADR1, ADR2",
    phone_numbers       => "TELEPHONE / MOBILE",
};

is_deeply(CRP::Util::PDF::_extract_crp_data($data), $expected, "_extract_crp_data [1]");

$profile->telephone(undef);
$expected->{telephone} = undef;
$expected->{phone_numbers} = 'MOBILE';
is_deeply(CRP::Util::PDF::_extract_crp_data($data), $expected, "_extract_crp_data [2:mobile only]");

$profile->telephone('TELEPHONE');
$profile->mobile(undef);
$expected->{telephone} = 'TELEPHONE';
$expected->{phone_numbers} = 'TELEPHONE';
$expected->{mobile} = undef;
is_deeply(CRP::Util::PDF::_extract_crp_data($data), $expected, "_extract_crp_data [2:telephone only]");

done_testing();
