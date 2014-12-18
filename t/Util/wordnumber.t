use Test::More;
use CRP::Util::WordNumber;

my %results;
for(0..500) {
    _test_wordnum($_);
    _test_wordnum(int(rand(100000)));
}

sub _test_wordnum {
    my($fixture) = @_;

    my $string = CRP::Util::WordNumber::encode_number($fixture);
    my $test = "wordnum $fixture => [$string]:";

    ok( (! exists $results{$string}) || $results{$string} eq $fixture, "$test encoding is unique");
    $results{$string} = $fixture;

    my @digits = split m{-}, $string;
    shift @digits if $digits[0] =~ m{^\d+$};
    ok(m{[a-z]+}i, "$test digit '$_' is a word") foreach @digits;

    my $result = CRP::Util::WordNumber::decode_number($string);
    is($result, $fixture, "$test decodes correctly");

    my $cipher = CRP::Util::WordNumber::encipher($fixture);
    $test = "cipher $fixture => [$cipher]";

    ok( (! exists $results{$cipher}) || $results{$cipher} eq $fixture, "$test encoding is unique");
    $results{$cipher} = $fixture;

    ok($cipher =~ m{^\d+$}, "$test cipher is a number");

    is($fixture, CRP::Util::WordNumber::decode_number($cipher), "$test decodes correctly");
}

done_testing();
