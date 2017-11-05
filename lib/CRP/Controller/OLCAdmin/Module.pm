package CRP::Controller::OLCAdmin::Module;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';

use CRP::Model::OLC::Module;
use CRP::Model::OLC::ModuleSet;
use CRP::Model::OLC::CourseSet::WithModule;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub edit {
    my $c = shift;

    $c->_display_module_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub save {
    my $c = shift;

    my $module = CRP::Model::OLC::Module->new(id => $c->_module_id, dbh => $c->crp->model);

    $c->_collect_input($module, [qw(name notes description title)]);

    if($c->validation->has_error) {
        $c->stash(msg => 'fix_errors');
        $c->_display_module_editor($module);
    }
    else {
        my $url;
        if($module->id) {
            $c->flash(msg => 'olc_module_update');
            $url = $c->url_for('crp.olcadmin.course.edit')->query(course_id => $c->_course_id);
        }
        else {
            $c->flash(msg => 'olc_module_create');
            $url = $c->url_for('crp.olcadmin.course.pickmodules')->query(course_id => $c->_course_id);
        }
        $module->create_or_update;
        return $c->redirect_to($url);
    }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub pickpages {
    my $c = shift;

    my $course          = CRP::Model::OLC::Course->new(id => $c->_course_id, dbh => $c->crp->model);
    my $module          = CRP::Model::OLC::Module->new(id => $c->_module_id, dbh => $c->crp->model);
    my $pages           = CRP::Model::OLC::PageSet->new(dbh => $c->crp->model);
    my $module_courses  = CRP::Model::OLC::CourseSet::WithModule->new(module_id => $module->id, dbh => $c->crp->model);
    my $module_pages    = $c->_module_page_set;
    my $pages_view_data = $pages->view_data;
    foreach my $page (@$pages_view_data) {
        $page->{_already_in_module} = $module_pages->includes_id($page->{id});
    }
    $c->stash(
        course         => $course->view_data,
        module         => $module->view_data,
        pages          => $pages_view_data,
        module_courses => $module_courses->view_data,
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub addpages {
    my $c = shift;

    my $module_pages = $c->_module_page_set;
    foreach my $page_id (@{$c->every_param('add_page')}) {
        $module_pages->add_page($page_id);
    }

    $c->_restart_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub pageup {
    my $c = shift;

    $c->_module_page_set->move_up($c->_page_id);
    $c->_restart_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub pagedown {
    my $c = shift;

    $c->_module_page_set->move_down($c->_page_id);
    $c->_restart_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub pagedelete {
    my $c = shift;

    $c->_module_page_set->delete($c->_page_id);
    $c->_restart_editor;
}

sub _module_page_set {
    my $c = shift;

    return CRP::Model::OLC::PageSet::ForModule->new(module_id => $c->_module_id, dbh => $c->crp->model);
}

sub _restart_editor {
    my $c = shift;

    return $c->redirect_to($c->url_for('crp.olcadmin.module.edit')->query(course_id => $c->_course_id, module_id => $c->_module_id));
}

sub _display_module_editor {
    my $c = shift;
    my($module) = @_;

    $module = CRP::Model::OLC::Module->new(id => $c->_module_id, dbh => $c->crp->model) unless $module;
    my $module_courses = CRP::Model::OLC::CourseSet::WithModule->new(module_id => $module->id, dbh => $c->crp->model);
    $c->stash(
        module         => $module->view_data,
        olc_course_id  => $c->_course_id,
        module_courses => $module_courses->view_data,
    );
    $c->render(template => 'o_l_c_admin/module/editor');
}

1;

