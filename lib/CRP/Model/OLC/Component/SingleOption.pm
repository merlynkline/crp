package  CRP::Model::OLC::Component::SingleOption;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $component_data = $self->data;
    my $data = {
        %{super()},
        prompt         => $component_data->{prompt} // '',
        options        => $component_data->{options} // [],
        correct_answer => $component_data->{correct_answer} // 0,
        preview        => substr($component_data->{prompt}, 0, 50),
    };
    return $data;
};

around 'data' => __PACKAGE__->can('_json_encoder');


__PACKAGE__->meta->make_immutable;

1;

