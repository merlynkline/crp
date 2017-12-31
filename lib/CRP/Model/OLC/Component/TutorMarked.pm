package  CRP::Model::OLC::Component::TutorMarked;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::UntypedComponent';

override 'view_data' => sub {
    my $self = shift;

    my $component_data = $self->data;
    my $data = {
        %{super()},
        prompt         => $component_data->{prompt} // '',
        preview        => substr($component_data->{prompt}, 0, 50),
    };
    return $data;
};

around 'data' => __PACKAGE__->can('_json_encoder');

sub is_good_answer {
    my $self = shift;
    my($answer) = @_;

    return '';
}

__PACKAGE__->meta->make_immutable;

1;

