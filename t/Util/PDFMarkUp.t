use Test::More;
use Mock::Quick;

use strict;
use warnings;

use CRP::Util::PDFMarkUp;

my $data = {A => 'a', B => 'b'};
my $str = 'Variable [% A %], variable [%  B  %]';


my $pdf_markup = CRP::Util::PDFMarkUp->new(file_path => '', test_mode => 0);
is($pdf_markup->_replace_place_holders($str, $data), 'Variable a, variable b', "_replace_place_holders normal mode");

$pdf_markup = CRP::Util::PDFMarkUp->new(file_path => '', test_mode => 1);
is($pdf_markup->_replace_place_holders($str), 'Variable [[ A ]], variable [[ B ]]', "_replace_place_holders test mode");

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
    date        => '',
    signature   => '',
    signature_url       => '',
    one_line_address    => "ADR1, ADR2",
    phone_numbers       => "TELEPHONE / MOBILE",
};

$pdf_markup->_extract_crp_data($data);
is_deeply($pdf_markup->_data, $expected, "_extract_crp_data [1]");

$profile->telephone(undef);
$expected->{telephone} = undef;
$expected->{phone_numbers} = 'MOBILE';
$pdf_markup->_extract_crp_data($data);
is_deeply($pdf_markup->_data, $expected, "_extract_crp_data [2:mobile only]");

$profile->telephone('TELEPHONE');
$profile->mobile(undef);
$expected->{telephone} = 'TELEPHONE';
$expected->{phone_numbers} = 'TELEPHONE';
$expected->{mobile} = undef;
$pdf_markup->_extract_crp_data($data);
is_deeply($pdf_markup->_data, $expected, "_extract_crp_data [2:telephone only]");

done_testing();
