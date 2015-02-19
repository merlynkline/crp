package CRP::Util::DateParser;
use Moose;

# Parse a day, month and year from a user-entered string.
# These are not validated except in the most basic way.
# It is assumed that the string is intended to represent
# a date of some sort. Other strings may still have three
# numbers successfully extracted even if they don't look
# anything like dates to a human observer.

has prefer_month_first_order    => (is => 'rw', isa => 'Bool', default => 1);

has day                         => (is => 'ro', isa => 'Int',  clearer => '_clear_day', writer => '_day');
has month                       => (is => 'ro', isa => 'Int',  clearer => '_clear_month', writer => '_month');
has year                        => (is => 'ro', isa => 'Int',  clearer => '_clear_year', writer => '_year');
has parsed_ok                   => (is => 'ro', isa => 'Bool', clearer => '_clear_parsed_ok', writer => '_parsed_ok');

has _possible_month_or_day      => (is => 'rw', isa => 'Int', clearer => '_clear__possible_month_or_day', init_arg => undef);

sub parse {
    my $self = shift;
    my($string) = @_;

    $self->_reset;
    my $tokens = _extract_tokens($string);
    $self->_parse_tokens($tokens) if @$tokens >= 3;

    return $self->parsed_ok;
}

sub _reset {
    my $self = shift;

    $self->_clear_day;
    $self->_clear_month;
    $self->_clear_year;
    $self->_clear_parsed_ok;
    $self->_clear__possible_month_or_day;
}

sub _extract_tokens {
    my($string) = @_;

    $string //= '';
    return [$1, $2, $3] if $string =~ m{^\s*(\d\d\d\d)(\d\d)(\d\d)\s*$};
    return [ $string =~ m{[a-z]+|\d+}ig ];
}

sub _parse_tokens {
    my $self = shift;
    my($tokens) = @_;

    foreach my $token (@$tokens) {
        return unless $self->_process_token($token);
        if($self->day && $self->month && defined $self->year) {
            $self->_parsed_ok(1);
            last;
        }
    }
}

sub _process_token {
    my $self = shift;
    my($token) = @_;

    if($token =~ m{^\d+$}) {
        return $self->_process_numeric_token($token);
    }
    else {
        return $self->_process_word_token($token);
    }
}

sub _process_numeric_token {
    my $self = shift;
    my($token) = @_;

    if($token > 31 || $token == 0 || length $token > 2 || ($self->month && $self->day)) {
        return 0 if defined $self->year;
        $self->_year($token + 0);
        return 1;
    }
    else {
        return $self->_process_month_or_day_token($token + 0);
    }
}

sub _process_month_or_day_token {
    my $self = shift;
    my($token) = @_;

    if($token > 12) {
        return 0 if $self->day;
        $self->_day($token);
        $self->_month($self->_possible_month_or_day) if $self->_possible_month_or_day;
    }
    else {
        $self->_store_month_or_day($token);
    }
    return 1;
}

sub _store_month_or_day {
    my $self = shift;
    my($token) = @_;

    if($self->month) {
        $self->_day($token);
    }
    elsif($self->day) {
        $self->_month($token);
    }
    else {
        $self->_check_uncertain_month_or_day($token);
    }
}

sub _check_uncertain_month_or_day {
    my $self = shift;
    my($token) = @_;

    if($self->_possible_month_or_day) {
        my $day = $self->_possible_month_or_day;
        my $month = $token;
        ($day, $month) = ($month, $day) if defined $self->year || $self->prefer_month_first_order;
        $self->_day($day);
        $self->_month($month);
    }
    else {
        $self->_possible_month_or_day($token);
    }
}

sub _process_word_token {
    my $self = shift;
    my($token) = @_;

    my $check_month = _month_from_name($token);
    return 1 unless $check_month;
    return 0 if $self->month;
    $self->_month($check_month);
    $self->_day($self->_possible_month_or_day) if $self->_possible_month_or_day;
    return 1;
}

sub _month_from_name {
    my($name) = @_;

    return unless length $name > 2;
    $name = lc $name;
    my $month = 0;
    foreach my $test_month (qw(
        january february march april may june julky august september october november december
    )) {
        $month++;
        return $month if substr($test_month, 0, length $name) eq $name;
    }
    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

