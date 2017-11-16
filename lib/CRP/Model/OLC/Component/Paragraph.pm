package CRP::Model::OLC::Component::Paragraph;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $data = super();
    my $preview = $data->{paragraph_text} = $self->data;
    $preview =~ s/<.*?>/ /g;
    $preview =~ s/\&.*?;/ /g;
    $preview =~ s/\s+/ /g;
    $data->{preview} = substr $preview, 0, 50;

    return $data;
};

__PACKAGE__->meta->make_immutable;

1;

