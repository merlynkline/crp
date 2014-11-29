package CRP::Util::Types;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(type_check);

use Carp;

my %CHECK = (
    MaxLen  => \&_check_MaxLen,
    MinLen  => \&_check_MinLen,
);

sub type_check {
    my($type, $value) = @_;

    foreach my $check (keys %$type) {
        if(exists $CHECK{$check}) {
            $CHECK{$check}->($type->{$check}, $value);
        }
        else {
            carp "Unrecognised type constraint: '$check'";
        }
    }
}

sub _fatal {
    my($code) = @_;

    croak "CRP::Util::Types::$code";
}

sub _safe_length {
    my($value) = @_;

    _fatal('_NotScalar') if ref $value;
    return defined $value ? length $value : 0;
}

sub _check_MinLen {
    my($min_length, $value) = @_;

    my $length = _safe_length($value);
    _fatal('MinLen') if $length < $min_length;
}

sub _check_MaxLen {
    my($max_length, $value) = @_;

    my $length = _safe_length($value);
    _fatal('MaxLen') if $length > $max_length;
}

1;

