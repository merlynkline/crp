package CRP::Model::OLC::Student;

use Moose;
use namespace::autoclean;

sub view_data {
    my $self = shift;

    return {
        name    => 'Student Olc',
        email   => 'student.olc@binary.co.uk',
    };
}

__PACKAGE__->meta->make_immutable;

1;

