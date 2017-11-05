package CRP::Controller::OLCAdmin::Component::EditorRole;

use Mojo::Role;

use CRP::Model::OLC::ModuleSet::WithPage;

sub _display_component_editor {
    my $c = shift;
    my($template) = @_;

    my $component = CRP::Model::OLC::Component->new({dbh => $c->crp->model, id => $c->_component_id});
    my $page_modules = CRP::Model::OLC::ModuleSet::WithPage->new(page_id => $c->_page_id, dbh => $c->crp->model);

    $c->stash(
        component      => $component->view_data,
        page_id        => $c->_page_id,
        course_id      => $c->_course_id,
        module_id      => $c->_module_id,
        page_modules   => $page_modules->view_data,
    );
    $c->render(template => $template);
}

1;

