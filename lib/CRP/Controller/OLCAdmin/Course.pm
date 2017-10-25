package CRP::Controller::OLCAdmin::Course;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';

use CRP::Model::OLC::Course;
use CRP::Model::OLC::CourseSet;
use CRP::Model::OLC::ModuleSet;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub edit {
    my $c = shift;

    $c->_display_course_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub save {
    my $c = shift;

    my $course = CRP::Model::OLC::Course->new(id => $c->_course_id, dbh => $c->crp->model);

    $c->_collect_input($course, [qw(name notes description title)]);

    if($c->validation->has_error) {
        $c->stash(msg => 'fix_errors');
        $c->_display_course_editor($course);
    }
    else {
        $c->flash(msg => $course->id ? 'olc_update' : 'olc_create');
        $course->create_or_update;
        return $c->redirect_to('crp.olcadmin.default');
    }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub pickmodules {
    my $c = shift;

    my $course_id       = $c->_course_id;
    my $course          = CRP::Model::OLC::Course->new(id => $course_id, dbh => $c->crp->model);
    my $modules         = CRP::Model::OLC::ModuleSet->new(dbh => $c->crp->model);
    my $course_modules  = $c->_course_module_set;
    my $modules_view_data = $modules->view_data;
    foreach my $module (@$modules_view_data) {
        $module->{_already_in_course} = $course_modules->includes_id($module->{id});
    }
    $c->stash(
        course  => $course->view_data,
        modules => $modules_view_data,
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub addmodules {
    my $c = shift;

    my $course_modules = $c->_course_module_set;
    foreach my $module_id (@{$c->every_param('add_module')}) {
        $course_modules->add_module($module_id);
    }

    $c->_restart_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub moduleup {
    my $c = shift;

    $c->_course_module_set->move_up($c->_module_id);
    $c->_restart_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub moduledown {
    my $c = shift;

    $c->_course_module_set->move_down($c->_module_id);
    $c->_restart_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub moduledelete {
    my $c = shift;

    $c->_course_module_set->delete($c->_module_id);
    $c->_restart_editor;
}

sub _course_module_set {
    my $c = shift;

    return CRP::Model::OLC::ModuleSet::ForCourse->new(course_id => $c->_course_id, dbh => $c->crp->model);
}

sub _restart_editor {
    my $c = shift;

    return $c->redirect_to($c->url_for('crp.olcadmin.course.edit')->query(course_id => $c->_course_id));
}

sub _display_course_editor {
    my $c = shift;
    my($course) = @_;

    $course = CRP::Model::OLC::Course->new(id => $c->_course_id, dbh => $c->crp->model) unless $course;
    $c->stash(course => $course->view_data);
    $c->render(template => 'o_l_c_admin/course/editor');
}


1;

