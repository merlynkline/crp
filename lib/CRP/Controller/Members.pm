package CRP::Controller::Members;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;

use CRP::Util::Misc;
use Try::Tiny;
use DateTime;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    my $days = $c->config->{course}->{age_when_advert_expires_days};
    my $profile = $c->crp->load_profile;
    $c->stash(incomplete_profile        => ! $profile->is_complete);
    $c->stash(draft_courses_count       => $profile->courses->get_draft_set->count);
    $c->stash(advertised_courses_count  => $profile->courses->get_advertised_set($days)->count);
    $c->stash(past_courses_count        => $profile->courses->get_past_set($days)->count);
    $c->stash(is_administrator          => $profile->login->is_administrator);
    $c->stash(instructors_trained       => [ $c->crp->model('InstructorQualification')->search({trainer_id => $profile->instructor_id}, {order_by => 'passed_date'}) ]);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub faqs {
    my $c = shift;

    my $faq_id = shift // $c->stash('faq_id');
    $c->stash('faq_id', $faq_id);

    $c->render(template => "members/faqs");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');
    $c->stash('page', $page);

    $c->render(template => "members/pages/$page");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub profile {
    my $c = shift;

    my $profile = $c->crp->load_profile;
    $c->stash(site_profile => $profile);

    if($c->req->method eq 'POST') {
        my $validation = $c->validation;

        my $profile_was_complete = $profile->is_complete;
        $c->_process_uploaded_photo;
        foreach my $field (qw(name address postcode telephone mobile blurb location latitude longitude)) {
            eval { $profile->$field($c->param($field)); };
            my $error = $@;
            if($error =~ m{^CRP::Util::Types::(.+?) }) {
                $validation->error($field => ["invalid_column_$1"]);
            }
            else {
                die $error if $error;
            }
        }
        $profile->hide_address(($c->param('hide_address') // '') eq 'Y' ? 'Y' : 'N');
        if($validation->has_error) {
            $c->stash(msg => 'fix_errors');
        }
        else {
            $c->_notify_admins_of_changes($profile) if $profile_was_complete;
            $profile->update;
            $c->flash(msg => 'profile_update');
            return $c->redirect_to('crp.members.profile');
        }
    }
    $c->param('hide_address', $profile->hide_address ? 'Y' : '');
}

use CRP::Util::Graphics;
sub _process_uploaded_photo {
    my $c = shift;

    my $photo = $c->req->upload('photo');
    return unless $photo->size;

    if($photo->size > ($c->config->{instructor_photo}->{max_size} || 10_000_000)) {
        $c->validation->error(photo => ['file_too_large']);
        return;
    }

    use File::Temp;
    my($fh, $temp_file) = tmpnam();
    close $fh;

    my $error;
    try {
        $photo->move_to($temp_file);
        if(CRP::Util::Graphics::resize(
                $temp_file,
                $c->config->{instructor_photo}->{width},
                $c->config->{instructor_photo}->{height},
            )) {
            use File::Copy;
            my $target = $c->crp->path_for_instructor_photo($c->crp->logged_in_instructor_id);
            move $temp_file, $target or die "Failed to move '$temp_file' to '$target': $!";
        }
        else {
            $c->validation->error(photo => ['invalid_image_file']);
        }
    }
    catch {
        $error = $_;
    };
    unlink $temp_file;
    die $error if $error;
}

sub _notify_admins_of_changes {
    my $c = shift;
    my($profile) = @_;

    my %changes = $profile->get_dirty_columns;
    my %important_changes;
    foreach my $important_column (qw(name address telephone location)) {
        $important_changes{$important_column} = $changes{$important_column} if exists $changes{$important_column};
    }
    if(%important_changes) {
        my $slug = '-' . CRP::Util::WordNumber::encipher($profile->instructor_id);
        $c->mail(
            to          => $c->crp->email_to($c->app->config->{email_addresses}->{user_admin}),
            template    => 'members/email/profile_update',
            info        => {
                changes => \%important_changes,
                id      => $profile->instructor_id,
                url     => $c->url_for('crp.membersite.home', slug => $slug)->to_abs,
            },
        );
    }
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDFMarkUp;
sub get_pdf {
    my $c = shift;

    my $pdf = shift // $c->stash('pdf');
    $pdf = $c->app->home->rel_file("pdfs/$pdf.pdf");
    return $c->reply->not_found unless -r $pdf;

    my $pdf_doc = CRP::Util::PDFMarkUp->new(file_path => $pdf);
    $c->_send_pdf_response($pdf_doc);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDFMarkUp;
sub course_pdf {
    my $c = shift;

    my $course_id = $c->stash('course_id');
    my $name = $c->stash('name');
    my $course = $c->crp->model('Course')->find({id => $course_id});
    die "You can't download a PDF for this course" unless $course && $course->instructor_id == $c->crp->logged_in_instructor_id;
    my $pdf = $c->app->home->rel_file("pdfs/${name}.pdf");
    my $pdf_doc = CRP::Util::PDFMarkUp->new(file_path => $pdf);

    $c->_send_pdf_response($pdf_doc, {course  => $course});
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
sub find_enquiries {
    my $c = shift;

    $c->crp->load_profile;
    my $latitude = $c->param('latitude') // '';
    my $longitude = $c->param('longitude') // '';
    my $file_name_location = $c->param('location') // '';
    $file_name_location =~ s{[^a-z0-9\s]}{}gi;
    $c->stash(file_name_location => substr($file_name_location, 0, 20)); # For CSV filename
    if($latitude ne '' && $longitude ne '') {
        my $enquiries_list = [
            $c->crp->model('Enquiry')->search_near_location(
                $latitude,
                $longitude,
                $c->config->{enquiry_search_distance},
                { notify_tutors => 1 },
                { order_by => {-desc => 'create_date'} },
            )
        ];
        $c->stash(enquiries_list => $enquiries_list);
    }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub courses {
    my $c = shift;

    my $profile = $c->crp->load_profile;
    my $days = $c->config->{course}->{age_when_advert_expires_days};
    my $courses = $profile->courses;
    $c->stash(
        advertised_list         => _date_order_list(scalar $courses->get_advertised_set($days)),
        draft_list              => _date_order_list(scalar $courses->get_draft_set),
        past_list               => _date_order_list(scalar $courses->get_past_set($days)),
        canceled_list           => _date_order_list(scalar $courses->get_canceled_set($days)),
        available_course_types  => $c->_available_course_types($profile),
        is_instructor_trainer   => $c->_is_instructor_trainer($profile),
    );
}

sub _is_instructor_trainer {
    my $c = shift;
    my($profile) = @_;

    return $c->crp->model('CourseType')->search(
        {
            'instructor_qualification.instructor_id' => $profile->instructor_id,
            qualification_earned_id => { '!=', undef },
        },
        {
            join    => 'instructor_qualification',
        }
    )->count > 0;
}

sub _date_order_list {
    my($result_set) = @_;

    return [ $result_set->search(undef, { order_by => {-asc => 'start_date'} }) ];
}

sub _available_course_types {
    my $c = shift;
    my($profile, $edited_course_id) = @_;

    my @course_types = $c->crp->model('CourseType')->search(
        {
            'instructor_qualification.instructor_id' => $profile->instructor_id,
            qualification_earned_id => undef,
        },
        {
            join    => 'instructor_qualification',
            columns => [qw(id abbreviation description qualification_required_id)],
            distinct=> 1,
            order_by=> 'id',
        }
    );

    return [] unless @course_types;

    my @trainee_qualifications = grep { $_->is_trainee } $profile->qualifications;

    return \@course_types unless @trainee_qualifications;

    my %trainee_qualification = map { $_->qualification_id => 1 } @trainee_qualifications;

    my %available_course_type = map { $_->id => $_ } @course_types;

    foreach my $course ($profile->courses) {
        next if $course->canceled;
        next if $edited_course_id && $course->id == $edited_course_id;
        next unless exists $trainee_qualification{$course->course_type->qualification_required_id};
        foreach my $course_type (@course_types) {
            delete $available_course_type{$course_type->id} if $course_type->qualification_required_id == $course->course_type->qualification_required_id;
        }
    }

    return [ sort { $b->id <=> $a->id } values %available_course_type ];
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
        return $c->redirect_to('crp.members.courses');
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
        $course = $c->crp->model('Course')->new_result({});
        $course->canceled(0);
        $course->published(0);
    }
    return $course;
}

sub _load_editable_course {
    my $c = shift;
    my($course_id) = @_;

    my $course = $c->crp->model('Course')->find({id => $course_id});
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
        time                => $c->crp->trimmed_param('time'),
        price               => $c->crp->trimmed_param('price'),
        book_excluded       => ($c->param('include_book') // '') eq 'Y' ? 'N' : 'Y',
        session_duration    => $c->crp->trimmed_param('session_duration'),
        course_duration     => $c->crp->trimmed_param('course_duration'),
        course_type_id      => $c->crp->trimmed_param('course_type_id') || 0,
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
    if( ! $course->published && $record->{start_date}) {
        if($record->{start_date} < DateTime->now) {
            $validation->error(start_date => ['future_date']);
        }
        else {
            my $course_type_id = $record->{course_type_id};
            if($course_type_id) {
                my $qualification_required_id = $c->crp->model('CourseType')->find($course_type_id)->qualification_required_id;
                $validation->error(course_type_id => ['trainee_qual_reused']) if _is_used_trainee_qualification($profile, $qualification_required_id);
                foreach my $qualification($profile->qualifications) {
                    if($qualification->qualification_id == $qualification_required_id) {
                        $validation->error(start_date => ['before_qualification']) unless $qualification->is_trainee || $record->{start_date} > $qualification->passed_date;
                        last;
                    }
                }
            }
        }
    }
    $validation->error(course_type_id => ['no_course_type']) unless $record->{course_type_id};

    return $validation;
}

sub _is_used_trainee_qualification {
    my($profile, $qualification_id) = @_;

    my %used_trainee_qualifications;

    my @trainee_qualifications = grep { $_->is_trainee } $profile->qualifications;

    if(@trainee_qualifications) {
        my %trainee_qualification = map { $_->qualification_id => 1 } @trainee_qualifications;
        return unless exists $trainee_qualification{$qualification_id};

        foreach my $course ($profile->courses) {
            next if $course->canceled;
            return 1 if $course->course_type->qualification_required_id == $qualification_id;
        }
    }

    return;
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
    $course->session_duration($config->{default_session_duration});
    $course->course_duration($config->{default_course_duration});
}

sub _display_course_editor_with {
    my $c = shift;
    my($course) = @_;

    my $profile = $c->crp->load_profile;
    $c->param(course_type_id => $course->course_type_id // '');
    $c->param(include_book   => ( ! $course->book_excluded || $course->book_excluded eq 'N') ? 'Y' : '');
    $c->stash(
        site_profile            => $profile,
        course_record           => $course,
        available_course_types  => $c->_available_course_types($profile, $course->id),
    );
    $c->stash('edit_restriction', 'PUBLISHED') if $course->published;
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
    return $c->redirect_to('crp.members.courses');
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
    $c->_notify_enquirers($course);
    $c->flash(msg => 'course_publish');
    return $c->redirect_to('crp.members.courses');
}

sub _load_publishable_course {
    my $c = shift;
    my($course_id) = @_;

    my $course = $c->_load_editable_course($course_id);
    die "You can't pubish this course" unless $course->is_publishable;
    my $profile = $c->crp->load_profile;
    die "You can't publish courses in demonstration accounts" if $profile->login->is_demo;
    return $course;
}

sub _notify_enquirers {
    my $c = shift;
    my($course) = @_;

    my $latitude = $course->latitude || return;
    my $longitude = $course->longitude || return;
    my $enquiries_list = [
        $c->crp->model('Enquiry')->search_near_location(
            $latitude,
            $longitude,
            $c->config->{enquiry_search_distance},
            { notify_new_courses => 1 },
        )
    ];
    foreach my $enquiry (@$enquiries_list) {
        $c->_notify_enquirer($enquiry, $course);
    }
}

sub _notify_enquirer {
    my $c = shift;
    my($enquiry, $course) = @_;

    return unless $enquiry->email;
    my $identifier = CRP::Util::WordNumber::encode_number($enquiry->id);
    my $profile = $c->crp->load_profile;
    my $url = $c->url_for('crp.membersite.course', slug => $profile->web_page_slug, course => $course->id)->to_abs;
    $c->mail(
        to          => $c->crp->email_to($enquiry->email, $enquiry->name),
        template    => 'members/email/course_published_to_enquirer',
        info        => {
            name            => $enquiry->name,
            url             => $url,
            confirm_page    => $c->url_for('/update_registration')->query(id => $identifier)->to_abs(),
        },
    );
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
    return $c->redirect_to('crp.members.courses');
}

sub _load_cancelable_course {
    my $c = shift;
    my($course_id) = @_;

    my $course = $c->crp->model('Course')->find({id => $course_id});
    die "You can't cancel this course" unless $course && $course->is_cancelable_by_instructor($c->crp->logged_in_instructor_id);
    return $course;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub course_docs {
    my $c = shift;

    my $course_id = $c->param('course_id');
    my $course = $c->crp->model('Course')->find({id => $course_id});
    die "You can't download documents for this course" unless $course && $course->instructor_id == $c->crp->logged_in_instructor_id;
    $c->stash('crp_session')->variable('course_id', $course_id);
    $c->stash('course_record', $course);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub pdf_image {
    my $c = shift;

    my $name = $c->stash('name');
    return $c->reply->not_found unless $name =~ m{\.jpg$}i;
    $c->res->headers->content_type('image/jpg');
    $c->reply->static("../pdfs/$name");
}

1;

