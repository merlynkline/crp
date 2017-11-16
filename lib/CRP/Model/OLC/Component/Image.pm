package CRP::Model::OLC::Component::Image;
use Moose;
use namespace::autoclean;

use Mojo::JSON qw(decode_json encode_json);

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $data = super();
    my $component_data = $self->data;
    my $preview = $data->{image_path} = $component_data->{path} // '';
    $data->{image_format} = $component_data->{format} // '';
    $data->{image_file} = $component_data->{file} // '';
    $preview =~ s{^.+/}{};
    $data->{preview} = $preview;
    return $data;
};

override 'data' => sub {
    my $self = shift;

    if(@_) {
        my ($data) = @_;
        $data = encode_json($data) if $data;
        return super($data);
    }
    my $data = super();
    $data = decode_json($data) if $data;
    return $data;
};

__PACKAGE__->meta->make_immutable;

1;

