package CRP::Controller::OLCAdmin::Page;

use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';

use CRP::Model::OLC::Page;
use CRP::Model::OLC::PageSet;
use CRP::Model::OLC::ModuleSet::WithPage;
use CRP::Model::OLC::ComponentSet::ForPage;
use CRP::Model::OLC::ResourceStore;

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub addcomponent {
    my $c = shift;

    my $component_type = $c->crp->trimmed_param('type');

    my $component_id;
    if($component_type) {
        try {
            $component_id = $c->_page_component_set->add($component_type);
        }
        catch {
            my $error = $_;
            warn "Failed to create component type '$component_type': $error";
            $c->validation->error(type => ['bad_component_type']);
        }
    }
    else {
        $c->validation->error(type => ['no_component_type']);
    }

    if($c->validation->has_error) {
        return $c->_display_page_editor;
    }
    my $url = $c->url_for('crp.olcadmin.component.edit')->query(
        course_id    => $c->_course_id,
        module_id    => $c->_module_id,
        page_id      => $c->_page_id,
        component_id => $component_id,
    );
    return $c->redirect_to($url);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub componentup {
    my $c = shift;

    $c->_page_component_set->move_up($c->_component_id);
    $c->_restart_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub componentdown {
    my $c = shift;

    $c->_page_component_set->move_down($c->_component_id);
    $c->_restart_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub componentdelete {
    my $c = shift;

    $c->_page_component_set->delete($c->_component_id);
    $c->_restart_editor;
}

sub _page_component_set {
    my $c = shift;

    return CRP::Model::OLC::ComponentSet::ForPage->new(page_id => $c->_page_id, dbh => $c->crp->model);
}

sub _restart_editor {
    my $c = shift;

    return $c->redirect_to($c->url_for('crp.olcadmin.page.edit')->query(
            page_id      => $c->_page_id,
            module_id    => $c->_module_id,
            component_id => $c->_component_id,
            course_id    => $c->_course_id,
    ));
}

sub _display_page_editor {
    my $c = shift;
    my($page) = @_;

    $page = CRP::Model::OLC::Page->new(id => $c->_page_id, dbh => $c->crp->model) unless $page;
    my $page_modules = CRP::Model::OLC::ModuleSet::WithPage->new(page_id => $page->id, dbh => $c->crp->model);
    $c->stash(
        page                 => $page->view_data($c->_module, $c->_course),
        olc_course_id        => $c->_course_id,
        olc_module_id        => $c->_module_id,
        component_id         => $c->_component_id,
        page_modules         => $page_modules->view_data,
        video_thumb_base_url => CRP::Model::OLC::ResourceStore->new(c => $c)->url_base('file/video_thumb'),
        video_base_url       => undef,
    );
    $c->render(template => 'o_l_c_admin/page/editor');
}

1;

