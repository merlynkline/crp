package CRP::Controller::OLCAdmin::Component::EditorRole;

use Mojo::Role;

use CRP::Model::OLC::ModuleSet::WithPage;

sub _display_component_editor {
    my $c = shift;
    my($template) = @_;

    my $page_modules = CRP::Model::OLC::ModuleSet::WithPage->new(page_id => $c->_page_id, dbh => $c->crp->model);

    $c->stash(
        component      => $c->_component->view_data($c->_module, $c->_course),
        olc_page_id    => $c->_page_id,
        olc_course_id  => $c->_course_id,
        olc_module_id  => $c->_module_id,
        page_modules   => $page_modules->view_data,
    );
    $c->render(template => $template);
}

sub _component {
    my $c = shift;

    return CRP::Model::OLC::Component->new({dbh => $c->crp->model, id => $c->_component_id});
}

sub _return_to_page_editor {
    my $c = shift;

    return $c->redirect_to($c->url_for('crp.olcadmin.page.edit')->query(
        page_id => $c->_page_id,
        module_id => $c->_module_id,
        course_id => $c->_course_id
    ));
}

1;

