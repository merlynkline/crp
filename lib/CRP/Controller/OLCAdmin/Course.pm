package CRP::Controller::OLCAdmin::Course;

use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

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

    my $course = CRP::Model::OLC::Course->new(id => $c->param('id'), dbh => $c->crp->model);

    my $course_input = {};
    foreach my $field (qw(name notes description title)) {
        $course_input->{$field} = $c->crp->trimmed_param($field);
    }

    foreach my $field (keys %$course_input) {
        try {
            $course->$field($course_input->{$field});
        }
        catch {
            my $error = $_;
            if($error =~ m{^CRP::Util::Types::(.+?) }) {
                $c->validation->error($field => ["invalid_column_$1"]);
            }
            else {
                die "$field: $error";
            }
        }
    }

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

    my $course_id       = $c->param('course_id');
    my $course          = CRP::Model::OLC::Course->new(id => $course_id, dbh => $c->crp->model);
    my $modules         = CRP::Model::OLC::ModuleSet->new(dbh => $c->crp->model);
    my $course_modules  = CRP::Model::OLC::ModuleSet::ForCourse->new(course_id => $course_id, dbh => $c->crp->model);
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

    my $course_id = $c->param('course_id');
    my $course_modules = CRP::Model::OLC::ModuleSet::ForCourse->new(course_id => $course_id, dbh => $c->crp->model);
    foreach my $module_id (@{$c->every_param('add_module')}) {
        $course_modules->add_module($module_id);
    }

    return $c->redirect_to($c->url_for('crp.olcadmin.course.edit')->query(id => $course_id));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub moduleup {
    my $c = shift;

    my $course_id = $c->param('course_id');
    my $module_id = $c->param('module_id');
    my $course_modules = CRP::Model::OLC::ModuleSet::ForCourse->new(course_id => $course_id, dbh => $c->crp->model);
    $course_modules->move_up($module_id);

    return $c->redirect_to($c->url_for('crp.olcadmin.course.edit')->query(id => $course_id));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub moduledown {
    my $c = shift;

    my $course_id = $c->param('course_id');
    my $module_id = $c->param('module_id');
    my $course_modules = CRP::Model::OLC::ModuleSet::ForCourse->new(course_id => $course_id, dbh => $c->crp->model);
    $course_modules->move_down($module_id);

    return $c->redirect_to($c->url_for('crp.olcadmin.course.edit')->query(id => $course_id));
}

sub _display_course_editor {
    my $c = shift;
    my($course) = @_;

    $course = CRP::Model::OLC::Course->new(id => $c->param('id'), dbh => $c->crp->model) unless $course;
    $c->stash(course => $course->view_data);
    $c->render(template => 'o_l_c_admin/course/editor');
}


1;

