package CRP::Model::OLC::StudentProgress;

use Moose;
use namespace::autoclean;

has student => (is => 'ro', isa => 'CRP::Model::OLC::Student');
has course  => (is => 'ro', isa => 'CRP::Model::OLC::Course');

sub view_data {
    my $self = shift;

    return {
        current_page_index  => 3,
    };
}

__PACKAGE__->meta->make_immutable;

1;

