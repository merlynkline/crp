package CRP::Model::Schema::ResultSet::Course;

use strict;
use warnings;

use base qw(DBIx::Class::ResultSet CRP::Model::Schema::location_search);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_live_courses {
    my $self = shift;
    my $earliest_date = shift;

    my $live_resultset = $self->search(
        {published => 1},
        {start_date => {'>', $earliest_date}},
    );
    return $live_resultset->search(@_);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_near_location {
    my $self = shift;
    my $earliest_date = shift;

    return $self->SUPER::search_near_location(@_)->search_live_courses($earliest_date);
}

1;

