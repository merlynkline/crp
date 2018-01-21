package CRP::Model::OLC::Component::PDF;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $data = super();
    my $component_data = $self->data;
    $data->{file} = $component_data->{file} // '';
    $data->{title} = $component_data->{title} || $data->{file};
    my $preview = $data->{file};
    $preview =~ s{^.+/}{};
    $data->{preview} = $preview;
    return $data;
};

around 'data' => __PACKAGE__->can('_json_encoder');

__PACKAGE__->meta->make_immutable;

1;

