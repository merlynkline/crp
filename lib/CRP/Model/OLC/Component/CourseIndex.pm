package CRP::Model::OLC::Component::CourseIndex;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;
    my($module_context, $course_context) = @_;

    confess "You must supply a course context" unless ref $course_context eq 'CRP::Model::OLC::Course';
    my $data = super();
    $data->{course} = $course_context->view_data;
    $data->{preview} = substr $course_context->name, 0, 50;
    return $data;
};

__PACKAGE__->meta->make_immutable;

1;

