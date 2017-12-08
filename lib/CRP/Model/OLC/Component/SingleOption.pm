package  CRP::Model::OLC::Component::SingleOption;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $data = super();
    my $component_data = $self->data;
    $data->{prompt} = $component_data->{prompt} // '';
    $data->{options} = $component_data->{options} // [];
    my $preview = $component_data->{prompt};
    $data->{preview} = substr $preview, 0, 50;
    return $data;
};

around 'data' => __PACKAGE__->can('_json_encoder');


__PACKAGE__->meta->make_immutable;

1;

