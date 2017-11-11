
package CRP::Controller::OLCAdmin::Component::CourseIDX;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use CRP::Model::OLC::Component;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    $c->_display_component_editor('o_l_c_admin/component/editor/courseidx');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub save {
    my $c = shift;

    my $component = $c->_component;
    $component->data_version(1);
    $component->name($c->crp->trimmed_param('name') || '(Course index)');
    $component->data('');
    $component->create_or_update;
    $c->_return_to_page_editor;
}

1;

