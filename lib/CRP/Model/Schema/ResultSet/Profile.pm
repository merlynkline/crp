package CRP::Model::Schema::ResultSet::Profile;

use strict;
use warnings;

use base qw(DBIx::Class::ResultSet CRP::Model::Schema::location_search);


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_live_profiles {
    my $self = shift;

    my $live_resultset = $self->search(
        {'login.disabled_date' => undef, is_demo => undef},
        {join => 'login'},
    );
    return $live_resultset->search(@_);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_near_location {
    my $self = shift;

    return $self->SUPER::search_near_location(@_)->search_live_profiles;
}

1;

