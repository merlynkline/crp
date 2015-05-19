package CRP::Model::Schema::ResultSet::InstructorCourse;

use strict;
use warnings;

use base qw(DBIx::Class::ResultSet CRP::Model::Schema::location_search);

use DateTime;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_live_courses {
    my $self = shift;
    my $earliest_date = shift;

    my $live_resultset = $self->search({
        published => 1,
        start_date => {'>', $self->_format_datetime($earliest_date)},
    });
    return $live_resultset->search(@_);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_near_location {
    my $self = shift;
    my $earliest_date = shift;

    return $self->SUPER::search_near_location(@_)->search_live_courses($earliest_date);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub get_draft_set {
    my $self = shift;

    return $self->search(
        { 
            published => 0,
            canceled  => 0,
        }
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub get_canceled_set {
    my $self = shift;

    return $self->search(
        { 
            canceled  => 1,
            start_date  => {'>', $self->_now},
        }
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub get_advertised_set {
    my $self = shift;

    return $self->search(
        {
            published   => 1,
            canceled    => 0,
            start_date  => {'>', $self->_now},
        },
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub get_past_set {
    my $self = shift;

    return $self->search(
        {
            published   => 1,
            start_date  => {'<=', $self->_now},
        },
    );
}

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

