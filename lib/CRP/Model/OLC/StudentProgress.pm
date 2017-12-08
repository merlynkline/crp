package CRP::Model::OLC::StudentProgress;

use Moose;
use namespace::autoclean;

has student => (is => 'ro', isa => 'CRP::Model::OLC::Student');
has course  => (is => 'ro', isa => 'CRP::Model::OLC::Course');

sub view_data {
    my $self = shift;
    my($page) = @_;

    my $data = {
        completed_pages_count  => $self->completed_pages_count,
    };

    if($page) {
        $data->{current_answer} = {
            52 => 1,
        }
    }

    return $data;
}

sub completed_pages_count {
    return 3;
}

__PACKAGE__->meta->make_immutable;

1;

