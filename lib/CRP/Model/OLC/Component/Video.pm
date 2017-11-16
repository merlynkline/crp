package CRP::Model::OLC::Component::Video;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $data = super();
    $data->{preview} = '(VIDEO-PREVIEW)';
    return $data;
};

__PACKAGE__->meta->make_immutable;

1;

