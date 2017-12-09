package  CRP::Model::OLC::Component::MultipleOption;
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
        correct_answer => { map { $_ => 1 } @{$component_data->{correct_answer} // []} },
        preview        => substr($component_data->{prompt}, 0, 50),
    };
    return $data;
};

around 'data' => __PACKAGE__->can('_json_encoder');

sub is_good_answer {
    my $self = shift;
    my($answer) = @_;

    $answer            = join ':', sort @{$answer || []};
    my $correct_answer = join ':', sort @{$self->data->{correct_answer} || []};
    return $answer eq $correct_answer;
}

__PACKAGE__->meta->make_immutable;

1;

