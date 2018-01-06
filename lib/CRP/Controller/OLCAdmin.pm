package CRP::Controller::OLCAdmin;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json);


use Try::Tiny;
use List::Util;

use CRP::Model::OLC::Course;
use CRP::Model::OLC::CourseSet;
use CRP::Model::OLC::Page;
use CRP::Model::OLC::Student;
use CRP::Model::OLC::StudentSet::Pending;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    $c->stash(
        course_list  => CRP::Model::OLC::CourseSet->new(dbh => $c->crp->model)->view_data,
        pending_list => CRP::Model::OLC::StudentSet::Pending->new(dbh => $c->crp->model)->view_data({course => 1}),
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub assignment {
    my $c = shift;

    my $student_id = $c->param('student');
    my $student;
    try { $student = CRP::Model::OLC::Student->new({dbh => $c->crp->model, id => $student_id}) };
    return $c->redirect_to('crp.olcadmin.default') unless $student && $student->status eq 'PENDING';

    return $c->_mark_assignment($student) if $c->req->method eq 'POST';

    my $last_page = CRP::Model::OLC::Page->new({dbh => $c->crp->model, id => $student->last_allowed_page_id});
    $c->stash(
        student => $student->view_data({
            course      => 1,
            assignments => 1,
            page        => $last_page,
        }),
        page    => $last_page->view_data,
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub remote {
    my $c = shift;

    my($error, $course_list);
    my $ua  = Mojo::UserAgent->new;
    try {
        my $res = $ua->get($c->url_for($c->config->{API}->{urlbase} . 'courses')->query(key => $c->config->{API}->{secret}))->result;
        if($res->is_success) {
            $course_list = decode_json($res->body);
        }
        else {
            $error = $res->code . ' - ' . $res->message;
        }
    }
    catch {
        $error = $_;
    };
    $c->stash(
        error       => $error,
        course_list => $course_list,
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub remote_update {
    my $c = shift;

    my $course;
    try {
        $course = CRP::Model::OLC::Course->new(guid => $c->param('guid'), dbh => $c->crp->model);
    };
    if($course) {
        $course = {
            name    => $course->name,
            title   => $course->title,
            state   => $course->state_data,
            action  => 'UPDATE',
        };
    }
    else {
        $course = {
            name    => $c->param('name'),
            title   => $c->param('title'),
            action  => 'NEW',
        };
    }

    use Data::Dumper; 
    $c->render(text => Dumper($course));
}

1;

