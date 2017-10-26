package CRP::Controller::OLCAdmin::Page;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';

use CRP::Model::OLC::Page;
use CRP::Model::OLC::PageSet;
use CRP::Model::OLC::ModuleSet::WithPage;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub edit {
    my $c = shift;

    $c->_display_page_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub save {
    my $c = shift;

    my $page = CRP::Model::OLC::Page->new(id => $c->param('page_id'), dbh => $c->crp->model);

    $c->_collect_input($page, [qw(name notes description title)]);

    if($c->validation->has_error) {
        $c->stash(msg => 'fix_errors');
        $c->_display_page_editor($page);
    }
    else {
        my $url;
        if($page->id) {
            $c->flash(msg => 'olc_page_update');
            $url = $c->url_for('crp.olcadmin.module.edit')->query(course_id => $c->_course_id, module_id => $c->_module_id);
        }
        else {
            $c->flash(msg => 'olc_page_create');
            $url = $c->url_for('crp.olcadmin.module.pickpages')->query(course_id => $c->_course_id, module_id => $c->_module_id);
        }
        $page->create_or_update;
        return $c->redirect_to($url);
    }
}

sub _restart_editor {
    my $c = shift;

    return $c->redirect_to($c->url_for('crp.olcadmin.page.edit')->query(page_id => $c->_page_id, module_id => $c->_module_id, course_id => $c->_course_id));
}

sub _display_page_editor {
    my $c = shift;
    my($page) = @_;

    $page = CRP::Model::OLC::Page->new(id => $c->_page_id, dbh => $c->crp->model) unless $page;
    my $page_modules = CRP::Model::OLC::ModuleSet::WithPage->new(page_id => $page->id, dbh => $c->crp->model);
    $c->stash(
        page           => $page->view_data,
        course_id      => $c->_course_id,
        module_id      => $c->_module_id,
        page_modules   => $page_modules->view_data,
    );
    $c->render(template => 'o_l_c_admin/page/editor');
}

1;

