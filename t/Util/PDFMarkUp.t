use Test::More;

use strict;
use warnings;

use CRP::Util::PDFMarkUp;

my $str = 'Variable [% A %], variable [%  B  %]';

my $pdf_markup = CRP::Util::PDFMarkUp->new(file_path => '', test_mode => 0);
$pdf_markup->_data({A => 'a', B => 'b'});

is($pdf_markup->_replace_place_holders($str), 'Variable a, variable b', "_replace_place_holders normal mode");

$pdf_markup = CRP::Util::PDFMarkUp->new(file_path => '', test_mode => 1);
is($pdf_markup->_replace_place_holders($str), 'Variable [[ A ]], variable [[ B ]]', "_replace_place_holders test mode");

done_testing();
