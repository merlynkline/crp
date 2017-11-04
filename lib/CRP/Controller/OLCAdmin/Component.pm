package CRP::Controller::OLCAdmin::Component;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';

use CRP::Model::OLC::Component;
use CRP::Model::OLC::ComponentSet;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub edit {
    my $c = shift;

    my $type = $c->trimmed_param('type');
    my $component = CRP::Model::OLC::Component->new;
    $component->type($type);
    _display_component_editor($component);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub save {
    my $c = shift;

    my $component = CRP::Model::OLC::Component->new(id => $c->param('component_id'), dbh => $c->crp->model);

    $c->_collect_input($component, [qw(name notes description title)]);

    if($c->validation->has_error) {
        $c->stash(msg => 'fix_errors');
        $c->_display_component_editor($component);
    }
    else {
        my $url;
        if($component->id) {
            $c->flash(msg => 'olc_component_update');
            $url = $c->url_for('crp.olcadmin.page.edit')->query(course_id => $c->_course_id, page_id => $c->_page_id);
        }
        else {
            $c->flash(msg => 'olc_component_create');
            $url = $c->url_for('crp.olcadmin.page.pickcomponents')->query(course_id => $c->_course_id, page_id => $c->_page_id);
        }
        $component->create_or_update;
        return $c->redirect_to($url);
    }
}

sub _restart_editor {
    my $c = shift;

    return $c->redirect_to($c->url_for('crp.olcadmin.component.edit')->query(component_id => $c->_component_id, page_id => $c->_page_id, course_id => $c->_course_id));
}

sub _display_component_editor {
    my $c = shift;
    my($component) = @_;

    my $component_pages = CRP::Model::OLC::PageSet::WithComponent->new(component_id => $component->id, dbh => $c->crp->model);
    $c->stash(
        component       => $component->view_data,
        course_id       => $c->_course_id,
        page_id         => $c->_page_id,
        component_pages => $component_pages->view_data,
    );
    $c->render(template => 'o_l_c_admin/component/editor');
}

1;

