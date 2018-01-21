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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub get_unique_file_name {
    my($base_dir, $proposed_name) = @_;

    my $try_count = 0;
    while(-f "$base_dir/$proposed_name") {
        $proposed_name =~ s/(^.+?)(\d*)(\.[^.]+)$/$1 . (($2 || 0) + 1) . $3/e;
        $try_count ++;
        $proposed_name = int(rand(10)) . $proposed_name if $try_count % 10 == 0;
    }

    return "$base_dir/$proposed_name";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub get_file_list {
    my($dir, $pattern) = @_;

    $pattern //= qr{^/([^.].+)$};
    my @files;
    use File::Find;
    find({wanted => sub {
                s{^$dir}{};
                push @files, $1 if m{$pattern};
            },
            no_chdir => 1,
        },
        $dir
    );
    return [sort {lc $a cmp lc $b} @files];
}


1;

