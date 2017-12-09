package CRP::Controller::OLCAdmin::Component::MultipleOption;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use Try::Tiny;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $extra_data = {};
    $c->_display_component_editor('o_l_c_admin/component/editor/multipleopt', $extra_data);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub save {
    my $c = shift;

    my $options = [];
    my $correct_answers = [];
    my $option_number = 0;
    while(defined(my $answer = $c->crp->trimmed_param("answer_$option_number"))) {
        my $required_answer = ! ! length($c->param("required_answer_$option_number") // '');
        if(length $answer || $required_answer) {
            push @$options, $answer;
            push @$correct_answers, $option_number if $required_answer;
        }
        $option_number++;
    }

    my $component = $c->_component;
    $component->data_version(1);
    $component->name($c->crp->trimmed_param('name'));
    $component->data({
        prompt         => $c->crp->trimmed_param('prompt'),
        correct_answer => $correct_answers,
        options        => $options,
    });
    $component->create_or_update;

    $c->_return_to_page_editor;
}

1;

