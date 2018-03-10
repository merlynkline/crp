package CRP::Model::OLC::Component::Video;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $data = super();
    my $component_data = $self->data;
    $data->{video_file} = $component_data->{file} // '';
    $data->{title} = $component_data->{title} || $data->{video_file};
    my $preview = $data->{video_file} . ' - ' . $data->{title};
    $preview =~ s{^.+/}{};
    $data->{preview} = $preview;
    return $data;
};

around 'data' => __PACKAGE__->can('_json_encoder');

__PACKAGE__->meta->make_immutable;

1;

