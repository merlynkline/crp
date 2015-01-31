use Test::More;
use Mock::Quick;

use strict;
use warnings;

use CRP::Util::DateParser;

my $parser = CRP::Util::DateParser->new;

my $fixtures = <<EOT;
24/1/1995:1995:01:24T09:08:17.1823213 ISO-8601
24/1/1995:1995-01-24T09:08:17.1823213
16/6/94:Wed, 16 Jun 94 07:29:35 CST 
13/10/94:Thu, 13 Oct 94 10:13:13 -0700
9/11/1994:Wed, 9 Nov 1994 09:50:32 -0500 (EST) 
21/12/17:21 dec 17:05 
21/12/17:21-dec 17:05
21/12/17:21/dec 17:05
21/12/93:21/dec/93 17:05
2/10/1999:1999 10:02:18 "GMT"
16/11/94:16 Nov 94 22:28:20 PST
10/11/2012:10 th Nov 2012
10/11/2012:10 Nov 2012
10/11/2012:Nov 10 th 2012
10/11/2012:Nov 10th 2012
10/11/2012:Nov 10 2012
10/11/2012:20121110
9/11/10:9Nov10
10/9/11:9-10-11
14/9/11:14-9-11
:23-23-11
:12Jib2012
:32Feb2012
1/2/3:1February03
:jafdhsj
EOT

test_date_parser($parser, $_) foreach (split "\n", $fixtures);

$fixtures = <<EOT;
24/1/1995:1995:01:24T09:08:17.1823213 ISO-8601
24/1/1995:1995-01-24T09:08:17.1823213
16/6/94:Wed, 16 Jun 94 07:29:35 CST 
13/10/94:Thu, 13 Oct 94 10:13:13 -0700
9/11/1994:Wed, 9 Nov 1994 09:50:32 -0500 (EST) 
21/12/17:21 dec 17:05 
21/12/17:21-dec 17:05
21/12/17:21/dec 17:05
21/12/93:21/dec/93 17:05
2/10/1999:1999 10:02:18 "GMT"
16/11/94:16 Nov 94 22:28:20 PST
10/11/2012:10 th Nov 2012
10/11/2012:10 Nov 2012
10/11/2012:Nov 10 th 2012
10/11/2012:Nov 10th 2012
10/11/2012:Nov 10 2012
10/11/2012:20121110
9/11/10:9Nov10
9/10/11:9-10-11
14/9/11:14-9-11
:23-23-11
:12Jib2012
:32Feb2012
1/2/3:1February03
:jafdhsj
EOT

$parser->prefer_month_first_order(0);
test_date_parser($parser, $_) foreach (split "\n", $fixtures);

foreach my $day (qw(1 9 10 11 19 21 28 31)) {
    foreach my $month (1 .. 12) {
        foreach my $year (qw(1 9 10 99 100 999 1000 1999 2000 2100)) {
            my $expected = "$day/$month/$year";
            $parser->prefer_month_first_order(1);
            test_date_parser($parser, "$expected:$month/$day/$year");
            test_date_parser($parser, sprintf "$expected:%04i%02i%02i", $year, $month, $day);
            $parser->prefer_month_first_order(0);
            test_date_parser($parser, "$expected:$day/$month/$year");
            test_date_parser($parser, sprintf "$expected:%04i%02i%02i", $year, $month, $day);
        }
    }
}


sub test_date_parser {
    my($parser, $fixture) = @_;

    my($date, $string) = split m{\s*:\s*}, $fixture, 2;
    my($d, $m, $y) = split m{\s*/\s*}, $date;
    $parser->parse($string);
    if($parser->parsed_ok) {
        ok($date ne '', "parsed, as expected: $string");
        is($parser->day, $d, "Extracted day '$d': $string");
        is($parser->month, $m, "Extracted month '$d': $string");
        is($parser->year, $y, "Extracted year '$d': $string");
    }
    else {
        ok($date eq '', "parse failed, as expected: $string");
    }
}

done_testing();

