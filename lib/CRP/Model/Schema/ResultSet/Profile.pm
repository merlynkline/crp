package CRP::Model::Schema::ResultSet::Profile;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_live_profiles {
    my $self = shift;

    my $live_resultset = $self->search(
        {'login.disabled_date' => undef},
        {join => 'login'},
    );
    return $live_resultset->search(@_);
}

1;

