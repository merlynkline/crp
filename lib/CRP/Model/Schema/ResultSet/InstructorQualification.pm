package CRP::Model::Schema::ResultSet::InstructorQualification;

use strict;
use warnings;

use base qw(DBIx::Class::ResultSet CRP::Model::Schema::date_utils);

sub get_passed_set {
    my $self = shift;

    return $self->search(
        {
            passed_date  => {'<=', $self->_now},
        },
    );
}

sub get_in_training_set {
    my $self = shift;

    return $self->search(
        {
            passed_date  => [ {'>', $self->_now}, {'=', undef} ],
        },
    );
}


1;

