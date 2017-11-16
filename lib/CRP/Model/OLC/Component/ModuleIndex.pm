package CRP::Model::OLC::Component::ModuleIndex;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;
    my($module_context, $course_context) = @_;

    confess "You must supply a module context" unless ref $module_context eq 'CRP::Model::OLC::Module';
    my $data = super();
    $data->{module} = $module_context->view_data;
    $data->{preview} = $module_context->name;
    $data->{preview} = substr $module_context->name, 0, 50;
    return $data;
};

__PACKAGE__->meta->make_immutable;

1;

