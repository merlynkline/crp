package CRP::Model::OLC::Component::Image;
use Moose;
use namespace::autoclean;

use Mojo::JSON qw(decode_json encode_json);

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

around 'data' => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
        my ($data) = @_;
        $data = encode_json($data) if $data;
        return $self->$orig($data);
    }
    my $data = $self->$orig;
    $data = decode_json($data) if $data;
    return $data;
};

__PACKAGE__->meta->make_immutable;

1;

