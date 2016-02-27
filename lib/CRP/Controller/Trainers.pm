package CRP::Controller::Trainers;

use Mojo::Base 'Mojolicious::Controller';

use DateTime;
use CRP::Util::Misc;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $c = shift;

    return 1 if $c->stash('login_record')->profile->instructor_trainer;
    $c->render(text => "Sorry - you aren't authorised to see this page", status => 403);
    return 0;
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub courses {
    my $c = shift;

    my $profile = $c->crp->load_profile;
    my $courses = $profile->instructors_courses;
    $c->stash(advertised_list   => _date_order_list(scalar $courses->get_advertised_set));
    $c->stash(draft_list        => _date_order_list(scalar $courses->get_draft_set));
    $c->stash(past_list         => _date_order_list(scalar $courses->get_past_set));
    $c->stash(canceled_list     => _date_order_list(scalar $courses->get_canceled_set));
}

sub _date_order_list {
    my($result_set) = @_;

    return [ $result_set->search(undef, { order_by => {-asc => 'start_date'} }) ];
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub course {
    my $c = shift;

    if($c->req->method eq 'POST') {
        $c->_create_or_update_course;
    }
    else {
        $c->_display_course_editor;
    }
}

sub _create_or_update_course {
    my $c = shift;

    my $course = $c->_get_new_or_existing_course;
    my $validation = $c->_load_course_from_params($course);
    if($validation->has_error) {
        $c->stash(msg => 'fix_errors');
        $c->_display_course_editor_with($course);
    }
    else {
        $c->flash(msg => $course->in_storage ? 'course_update' : 'course_create');
        $course->update_or_insert;
        return $c->redirect_to('crp.trainers.courses');
    }
}

sub _get_new_or_existing_course {
    my $c = shift;

    my $course_id = $c->param('course_id');
    my $course;
    if($course_id) {
        $course = $c->_load_editable_course($course_id);
    }
    else {
        $course = $c->crp->model('InstructorCourse')->new_result({});
        $course->canceled(0);
        $course->published(0);
    }
    return $course;
}

sub _load_editable_course {
    my $c = shift;
    my($course_id) = @_;

    my $course = $c->crp->model('InstructorCourse')->find({id => $course_id});
    die "You can't edit this course" unless $course && $course->is_editable_by_instructor($c->crp->logged_in_instructor_id);
    return $course;
}

sub _load_course_from_params {
    my $c = shift;
    my($course) = @_;

    my $profile = $c->crp->load_profile;
    my $validation = $c->validation;

    my $record = {
        instructor_id       => $profile->instructor_id,
        location            => $c->crp->trimmed_param('location'),
        latitude            => $c->crp->number_or_null($c->param('latitude')),
        longitude           => $c->crp->number_or_null($c->param('longitude')),
        venue               => $c->crp->trimmed_param('venue'),
        description         => $c->crp->trimmed_param('description'),
        start_date          => CRP::Util::Misc::get_date_input($c->crp->trimmed_param('start_date')),
        price               => $c->crp->trimmed_param('price'),
        qualification_id    => $c->crp->trimmed_param('qualification') || 0,
    };

    foreach my $column (keys %$record) {
        eval { $course->$column($record->{$column}); };
        my $error = $@;
        if($error =~ m{^CRP::Util::Types::(.+?) }) {
            $validation->error($column => ["invalid_column_$1"]);
        }
        else {
            die $error if $error;
        }
    }
    if( ! $course->published) {
        $validation->error(start_date => ['future_date'])
            unless $record->{start_date} && $record->{start_date} >= DateTime->now;
    }
    $validation->error(qualification => ['no_qualification']) unless $record->{qualification_id};

    return $validation;
}

sub _display_course_editor {
    my $c = shift;

    my $course = $c->_get_new_or_existing_course;
    $c->_load_course_from_defaults($course) unless $course->in_storage;
    $c->_display_course_editor_with($course);
}

sub _load_course_from_defaults {
    my $c = shift;
    my($course) = @_;

    my $profile = $c->crp->load_profile;
    my $config = $c->config->{course};
    $course->location($profile->location);
}

sub _display_course_editor_with {
    my $c = shift;
    my($course) = @_;

    my $profile = $c->crp->load_profile;
    $c->param(qualification => $course->qualification_id // '');
    $c->stash(site_profile => $profile);
    $c->stash('course_record', $course);
    $c->stash('edit_restriction', 'PUBLISHED') if $course->published;
    $c->stash(available_qualifications => [ $c->crp->model('Qualification')->search(undef, {order_by => 'abbreviation'}) ]);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub delete_course {
    my $c = shift;

    my $course_id = $c->param('course_id');
    my $course = $c->_load_editable_course($course_id);
    $c->stash('crp_session')->variable('course_id', $course_id);
    $c->stash('course_record', $course);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub do_delete_course {
    my $c = shift;

    my $course_id = $c->stash('crp_session')->remove_variable('course_id');
    my $course = $c->_load_editable_course($course_id);
    $c->flash(msg => 'course_delete');
    $course->delete;
    return $c->redirect_to('crp.trainers.courses');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub publish_course {
    my $c = shift;

    my $course_id = $c->param('course_id');
    my $course = $c->_load_publishable_course($course_id);
    $c->stash('crp_session')->variable('course_id', $course_id);
    $c->stash('course_record', $course);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub do_publish_course {
    my $c = shift;

    my $course_id = $c->stash('crp_session')->remove_variable('course_id');
    my $course = $c->_load_publishable_course($course_id);
    $course->publish;
    $c->flash(msg => 'course_publish');
    return $c->redirect_to('crp.trainers.courses');
}

sub _load_publishable_course {
    my $c = shift;
    my($course_id) = @_;

    my $course = $c->_load_editable_course($course_id);
    die "You can't pubish this course" unless $course->is_publishable;
    return $course;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub cancel_course {
    my $c = shift;

    my $course = $c->_load_cancelable_course($c->param('course_id'));
    $c->stash('crp_session')->variable('course_id', $course->id);
    $c->stash('course_record', $course);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub do_cancel_course {
    my $c = shift;

    my $course = $c->_load_cancelable_course($c->stash('crp_session')->remove_variable('course_id'));
    $c->stash('crp_session')->variable('course_id', $course->id);
    $course->cancel($c->crp->logged_in_instructor_id);
    $c->stash('course_record', $course);
    return $c->redirect_to('crp.trainers.courses');
}

sub _load_cancelable_course {
    my $c = shift;
    my($course_id) = @_;

    my $course = $c->crp->model('InstructorCourse')->find({id => $course_id});
    die "You can't cancel this course" unless $course && $course->is_cancelable_by_instructor($c->crp->logged_in_instructor_id);
    return $course;
}


1;

