package CRP::Util::Misc;

use Try::Tiny;
use DateTime;
use CRP::Util::DateParser;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub get_date_input {
    my($date) = @_;

    my $parser = CRP::Util::DateParser->new(prefer_month_first_order => 1);
    $parser->parse($date);
    return undef unless $parser->parsed_ok;
    my $res;
    try {
        $res = DateTime->new(
            year        => $parser->year,
            month       => $parser->month,
            day         => $parser->day,
            time_zone   => 'UTC',
        );
    };
    return $res;
}

1;

