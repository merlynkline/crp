package CRP::Controller::OLCAdmin::Component;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';

use CRP::Model::OLC::Component;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $component = CRP::Model::OLC::Component->new({dbh => $c->crp->model, id => $c->_component_id});
    my $route = {
        HEADING    => 'heading',
        PARAGRAPH  => 'paragraph',
        MARKDOWN   => 'markdown',
        COURSE_IDX => 'courseidx',
        MODULE_IDX => 'moduleidx',
    }->{$component->type};
    die "Don't know how to edit component type '" . $component->type . "'" unless $route;
    return $c->redirect_to($c->url_for("crp.olcadmin.component.$route.edit")->query(
        course_id    => $c->_course_id,
        module_id    => $c->_module_id,
        page_id      => $c->_page_id,
        component_id => $component->id,
    ));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

