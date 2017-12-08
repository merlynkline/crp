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

    my $component = $c->_component;
    $component->data_version(1);
    $component->name($c->crp->trimmed_param('name'));
    $component->data({
        prompt  => $c->crp->trimmed_param('prompt'),
    });
    $component->create_or_update;
    $c->_return_to_page_editor;
}

1;

