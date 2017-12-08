package CRP::Controller::OLCAdmin::Component::SingleOption;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use Try::Tiny;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $extra_data = {};
    $c->_display_component_editor('o_l_c_admin/component/editor/singleopt', $extra_data);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub save {
    my $c = shift;

    my $options = [];
    my $option_number = 0;
    my $correct_answer = $c->param('correct_answer') || 0;
    while(defined(my $answer = $c->crp->trimmed_param("answer_$option_number"))) {
        if(length $answer || $option_number == $correct_answer) {
            push @$options, $answer;
            $correct_answer = $#$options if $option_number == $correct_answer;
        }
        $option_number++;
    }

    my $component = $c->_component;
    $component->data_version(1);
    $component->name($c->crp->trimmed_param('name'));
    $component->data({
        prompt         => $c->crp->trimmed_param('prompt'),
        correct_answer => $correct_answer,
        options        => $options,
    });
    $component->create_or_update;

    $c->_return_to_page_editor;
}

1;

