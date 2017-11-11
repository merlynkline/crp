package CRP::Model::OLC::ComponentSet;
use Moose;
use namespace::autoclean;

use CRP::Model::OLC::Component;

extends 'CRP::Model::DBICIDObjectSet';

use constant {
    _RESULTSET_NAME => 'OLCComponent',
    _MEMBER_CLASS   => 'CRP::Model::OLC::Component',
};

sub view_data {
    my $self = shift;
    my($module_context, $course_context) = @_;

    return [ map $_->view_data($module_context, $course_context), @{$self->all} ];
}

__PACKAGE__->meta->make_immutable;

1;

