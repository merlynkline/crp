package  CRP::Model::OLC::Component::Heading;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $data = super();
    my $preview = $data->{heading_text} = $self->data // '';
    $data->{preview} = substr $preview, 0, 50;
    return $data;
};

__PACKAGE__->meta->make_immutable;

1;

