package CRP::Controller::OLCAdmin;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);


use Try::Tiny;
use List::Util;

use CRP::Model::OLC::Course;
use CRP::Model::OLC::CourseSet;
use CRP::Model::OLC::Page;
use CRP::Model::OLC::Component;
use CRP::Model::OLC::Student;
use CRP::Model::OLC::StudentSet::Pending;
use CRP::Model::OLC::ResourceStore;


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
    return $c->redirect_to('crp.olcadmin.default') unless $student;

    if($c->req->method eq 'POST') {
        $c->_mark_assignment($student);
        return $c->redirect_to($c->url_for('crp.olcadmin.assignment')->query(student => $student->id));
    }

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

sub _mark_assignment {
    my $c = shift;
    my($student) = @_;

    my $page_id = $student->last_allowed_page_id;
    return unless $page_id == $c->param('page');
    my $page = CRP::Model::OLC::Page->new({dbh => $c->crp->model, id => $page_id});

    my $component_id = $c->param('component');
    return unless $page->component_set->includes_id($component_id);
    my $component = CRP::Model::OLC::Component->new({dbh => $c->crp->model, id => $component_id});
    return unless $component->type eq 'QTUTORMARKED';
    return if $student->assignment_passed($page, $component);

    $student->assignment_passed($page, $component, 'PASS');
    $student->create_or_update_access_unchanged;

    $c->_send_student_notification_email($student) if $student->status eq 'IN_PROGRESS';

    return;
}

sub _send_student_notification_email {
    my $c = shift;
    my($student) = @_;

    my $course = $student->course;
    $c->mail(
        to          => $c->crp->email_to($student->email),
        template    => 'olc/email/assignment_mark_notification',
        info        => {
            course     => $course->view_data,
            student    => $student->view_data,
            course_url => $c->url_for('crp.olc.completed', course_id => $course->id, slug => 'kidsreflex')->to_abs,
        },
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub remote {
    my $c = shift;

    my($error, $course_list);
    try {
        $course_list = $c->_fetch_remote_data('courses');
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
        my $resource_store = CRP::Model::OLC::ResourceStore->new(c => $c);
        $course = {
            name    => $course->name,
            title   => $course->title,
            state   => $course->state_data($resource_store),
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

    my $remote_course = $c->_fetch_remote_data('course', {guid => $c->param('guid')});

    $c->render(text => encode_json({remote => $remote_course, local => $course}));
}

sub _fetch_remote_data {
    my $c = shift;
    my($path, $query) = @_;

    my($error, $data);
    my $ua  = Mojo::UserAgent->new;
    my $url = $c->config->{API}->{urlbase} . $path;

    my %query = %{$query // {}};
    $query{key} = $c->config->{API}->{secret};

    my $res = $ua->get($c->url_for($url)->query(%query))->result;
    if($res->is_success) {
        $data = decode_json($res->body);
    }
    else {
        die "Fetching '$url': " . $res->code . ' - ' . $res->message;
    }

    return $data;
}


1;

