package CRP::Model::OLC::Component::Image;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $data = super();
    my $component_data = $self->data;
    $data->{image_format} = $component_data->{format} // '';
    $data->{image_file} = $component_data->{file} // '';
    my $preview = $data->{image_file};
    $preview =~ s{^.+/}{};
    $data->{preview} = $preview;
    return $data;
};

override 'state_data' => sub {
    my $self = shift;

    my $data = super();
    $data->{content} = {
        timestamp   => "TIME",
        file        => $self->data->{file},
    };
    return $data;
};

around 'data' => __PACKAGE__->can('_json_encoder');

__PACKAGE__->meta->make_immutable;

1;

