package CRP::Controller::OLCAdmin::Component::Heading;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use CRP::Model::OLC::Component;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    $c->_display_component_editor('o_l_c_admin/component/editor/heading');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

