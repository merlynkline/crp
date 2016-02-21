package CRP::Model::Schema::ResultSet::Profile;

use strict;
use warnings;

use base qw(DBIx::Class::ResultSet CRP::Model::Schema::location_search CRP::Model::Schema::date_utils);


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_live_profiles {
    my $self = shift;

    my $live_resultset = $self->search(
        {'login.disabled_date' => undef, is_demo => [undef, 'f']},
        {join => 'login'},
    );
    return $live_resultset->search(@_);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_near_location {
    my $self = shift;

    return $self->SUPER::search_near_location(@_)->search_live_profiles;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_trainees {
    my $self = shift;

    $self->search_live_profiles->search(
        {
            'qualifications.passed_date' => [ {'>', $self->_now}, {'=', undef} ],
        },
        {
            join        => 'qualifications',
            distinct    => 1,
        },
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub search_qualified {
    my $self = shift;

    $self->search_live_profiles->search(
        {
            'qualifications.passed_date' => [ {'<=', $self->_now} ],
        },
        {
            join        => 'qualifications',
            distinct    => 1,
        },
    );
}

1;

