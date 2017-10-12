package CRP::Controller::OLCAdmin;

use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

use CRP::Model::OLC::Course;
use CRP::Model::OLC::CourseSet;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    $c->stash(course_list => CRP::Model::OLC::CourseSet->new(dbh => $c->crp->model)->get_data_for_template);

}

sub course {
    my $c = shift;

    if($c->req->method eq 'POST') {
        $c->_create_or_update_course;
    }
    else {
        $c->_display_course_editor;
    }
}

sub savecourse {
    my $c = shift;

    my $course = CRP::Model::OLC::Course->new(id => $c->param('course_id'), dbh => $c->crp->model);

    my $course_input = {};
    foreach my $field (qw(name description title)) {
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

sub _display_course_editor {
    my $c = shift;
    my($course) = @_;

    $course = CRP::Model::OLC::Course->new(id => $c->param('course_id'), dbh => $c->crp->model) unless $course;
    $c->stash(course => $course->get_data_for_template);
    $c->render(template => 'o_l_c_admin/course_editor');
}


1;

