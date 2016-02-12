package CRP::Model::Schema::date_utils;

use strict;
use warnings;

use DateTime;

sub _now {
    my $self = shift;
    my($age_days) = @_;

    return $self->_format_datetime(DateTime->now());
}

sub _format_datetime {
    my $self = shift;
    my($date) = @_;

    if(ref $date) {
        my $dtf = $self->result_source->schema->storage->datetime_parser;
        $date = $dtf->format_datetime($date);
    }
    return $date;
}


1;


