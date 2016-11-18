package CRP::Controller::Trainers;

use Mojo::Base 'Mojolicious::Controller';

use DateTime;
use CRP::Util::Misc;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $c = shift;

    return 1 if @{$c->_available_course_types($c->stash('login_record')->profile)};
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

    my $course = $c->crp->model('InstructorCourse')->find({id => $course_id, prefetch => 'course_type'});
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
        duration            => $c->crp->trimmed_param('duration'),
        course_type_id      => $c->crp->trimmed_param('course_type') || 0,
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
    $validation->error(course_type => ['no_course_type']) unless $record->{course_type_id};

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
    my $config = $c->config->{instructors_course};
    $course->duration($config->{default_course_duration});
    $course->location($profile->location);
}

sub _display_course_editor_with {
    my $c = shift;
    my($course) = @_;

    my $profile = $c->crp->load_profile;
    $c->param(course_type => $course->course_type_id // '');
    $c->stash(site_profile => $profile);
    $c->stash('course_record', $course);
    $c->stash('edit_restriction', 'PUBLISHED') if $course->published;
    $c->stash(available_course_types => $c->_available_course_types($profile));
}

sub _available_course_types {
    my $c = shift;
    my($profile) = @_;

    my @course_types = $c->crp->model('CourseType')->search(
        {
            'instructor_qualification.instructor_id' => $profile->instructor_id,
            -or => {
                qualification_earned_id => { '!=', undef },
                -bool => 'is_professional',
            },
        },
        {
            join    => 'instructor_qualification',
            columns => [qw(id abbreviation description qualification_required_id)],
            distinct=> 1,
            order_by=> 'description',
        }
    );

    return \@course_types;
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

    $c->_stash_course($c->crp->numeric_param('course_id'));
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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub course_docs {
    my $c = shift;

    $c->_stash_course($c->crp->numeric_param('id'));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDFMarkUp;
sub course_pdf {
    my $c = shift;

    my $course  = $c->_stash_course($c->stash('course_id'));
    my $name    = $c->stash('name');
    my $pdf     = $c->app->home->rel_file("pdfs/${name}.pdf");
    my $pdf_doc = CRP::Util::PDFMarkUp->new(file_path => $pdf);

    $c->_send_pdf_response($pdf_doc, {instructor_course  => $course});
}

use CRP::Util::CRPDataFormatter;
sub _send_pdf_response {
    my $c = shift;
    my($pdf_doc, $data) = @_;

    $data //= {};
    my $pdf_data = CRP::Util::CRPDataFormatter::format_data($c, {
        %$data,
        profile => $c->crp->load_profile,
        email   => $c->stash('crp_session')->variable('email'),
    });
    $c->render_file(
        data                => $pdf_doc->fill_template($pdf_data),
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
        filename            => $pdf_doc->filename,
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub attendees {
    my $c = shift;

    $c->_stash_course($c->crp->numeric_param('course_id') || $c->stash('crp_session')->variable('course_id'));
}

sub _stash_course {
    my $c = shift;
    my($course_id) = @_;

    my $course = $c->crp->model('InstructorCourse')->find({id => $course_id});
    die "You can't manage this course" unless $course && $course->instructor_id == $c->crp->logged_in_instructor_id;
    $c->stash('crp_session')->variable('course_id', $course_id);
    $c->stash('course_record', $course);
    return $course;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub attendee {
    my $c = shift;

    my $course = $c->_stash_course($c->stash('crp_session')->variable('course_id'));
    if($c->req->method eq 'POST') {
        $c->_create_or_update_attendee;
    }
    else {
        $c->_display_attendee_editor;
    }
}

sub _display_attendee_editor {
    my $c = shift;

    my $attendee = $c->_get_new_or_existing_attendee;
    my $is_new_attendee = ! $attendee->in_storage;
    $c->_load_attendee_from_defaults($attendee) if $is_new_attendee;
    $c->_display_attendee_editor_with($attendee);
}

sub _get_new_or_existing_attendee {
    my $c = shift;

    my $attendee_id = $c->param('attendee_id');
    my $attendee;
    if($attendee_id) {
        $attendee = $c->_get_existing_attendee($attendee_id);
    }
    else {
        $attendee = $c->crp->model('Professional')->new_result({});
    }
    return $attendee;
}

sub _get_existing_attendee {
    my $c = shift;

    my $attendee_id = $c->param('attendee_id');
    my $attendee;
    if($attendee_id) {
        my $course = $c->stash('course_record');
        $attendee = $c->crp->model('Professional')->find({id => $attendee_id});
        die "You can't edit this attendee" unless $attendee && $attendee->instructors_course_id == $course->id;
    }
    return $attendee;
}

sub _load_attendee_from_defaults {
    my $c = shift;
    my($attendee) = @_;

    my $course = $c->stash('course_record');
    my $last_attendee = $course->professionals->search(undef, {order_by => {-desc => 'id'}})->first;
    if($last_attendee) {
        foreach my $attribute (qw(organisation_name organisation_address organisation_postcode organisation_telephone)) {
            $attendee->$attribute($last_attendee->$attribute);
        }
    }
    $attendee->instructors_course_id($course->id);
}

sub _display_attendee_editor_with {
    my $c = shift;
    my($attendee) = @_;

    my $is_new_attendee = ! $attendee->in_storage;
    $c->stash(is_new_attendee => $is_new_attendee);
    $c->stash('attendee_record', $attendee);
}

sub _create_or_update_attendee {
    my $c = shift;

    my $attendee = $c->_get_new_or_existing_attendee;
    my $is_new_attendee = ! $attendee->in_storage;
    my $validation = $c->_load_attendee_from_params($attendee);
    if($validation->has_error) {
        $c->stash(msg => 'fix_errors');
        $c->_display_attendee_editor_with($attendee);
    }
    else {
        $c->flash(msg => $is_new_attendee ? 'attendee_create' : 'attendee_update');
        $attendee->update_or_insert;
        if($is_new_attendee) {
            $c->stash({
                attendee    => $attendee,
                slug        => CRP::Util::WordNumber::encode_number($attendee->id),
            });
            $c->mail(
                to          => $c->crp->email_to($attendee->email),
                template    => 'trainers/email/attendee_introduction',
            );
        }
        return $c->redirect_to('crp.trainers.attendees');
    }
}

sub _load_attendee_from_params {
    my $c = shift;
    my($attendee) = @_;

    my $validation = $c->validation;
    my $course = $c->stash('course_record');

    my $record = {
        instructors_course_id   => $course->id,
    };
    foreach my $field (qw(name email organisation_name organisation_address organisation_postcode organisation_telephone)) {
        $record->{$field} = $c->crp->trimmed_param($field);
        $validation->required($field);
    }
    $validation->required('email')->like(qr{^.+@.+[.].+});

    foreach my $column (keys %$record) {
        eval { $attendee->$column($record->{$column}); };
        my $error = $@;
        if($error =~ m{^CRP::Util::Types::(.+?) }) {
            $validation->error($column => ["invalid_column_$1"]);
        }
        else {
            die $error if $error;
        }
    }

    if( ! $validation->has_error && ! $attendee->in_storage) {
        my $duplicate_attendee = $c->crp->model('Professional')->find({
            email => $attendee->email,
            instructors_course_id => $course->id,
        });
        $validation->error(email => ['duplicate_email']) if $duplicate_attendee;
    }

    return $validation;
}

sub attendee_email {
    my $c = shift;

    return unless $c->_stash_attendee_and_course;
}

sub send_attendee_email {
    my $c = shift;

    return unless my $attendee = $c->_stash_attendee_and_course;

    $c->mail(
        to          => $c->crp->email_to($attendee->email),
        template    => 'trainers/email/attendee_introduction',
    );
}

sub _stash_attendee_and_course {
    my $c = shift;

    $c->_stash_course($c->stash('crp_session')->variable('course_id'));
    my $attendee = $c->_get_existing_attendee;
    if($attendee) {
        $c->stash({
            attendee    => $attendee,
            slug        => CRP::Util::WordNumber::encode_number($attendee->id),
        });
    }
    else {
        $c->reply->not_found;
    }
    return $attendee;
}



1;

