package CRP::Controller::Members;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;

use Try::Tiny;
use DateTime;
use CRP::Util::DateParser;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    my $profile = $c->_load_profile;
    $c->stash(incomplete_profile => ! $profile->is_complete);
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

    my $profile = $c->_load_profile;
    $c->stash(site_profile => $profile);

    if($c->req->method eq 'POST') {
        my $validation = $c->validation;

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
        if($validation->has_error) {
            $c->stash(msg => 'fix_errors');
        }
        else {
            $c->_notify_admins_of_changes($profile);
            $profile->update;
            $c->flash(msg => 'profile_update');
            return $c->redirect_to('crp.members.profile');
        }
    }
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


sub _load_profile {
    my $c = shift;

    my $instructor_id = $c->crp->logged_in_instructor_id or die "Not logged in";
    my $profile = $c->crp->model('Profile')->find_or_create({instructor_id => $instructor_id});
    $c->stash('profile_record', $profile);
    return $profile;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDFMarkUp;
sub get_pdf {
    my $c = shift;

    my $pdf = shift // $c->stash('pdf');
    $pdf = $c->app->home->rel_file("pdfs/members/$pdf.pdf");
    return $c->reply->not_found unless -r $pdf;

    my $profile = $c->_load_profile;
    my $url = $c->url_for('crp.membersite.home', slug => $profile->web_page_slug)->to_abs;
    $url =~ s{.+?://}{};
    my $pdf_doc = CRP::Util::PDFMarkUp->new(file_path => $pdf);
    my $data = {
        profile => $profile,
        url     => $url,
        email   => $c->stash('crp_session')->variable('email'),
    };
    $c->render_file(
        data                => $pdf_doc->fill_template($data),
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub find_enquiries {
    my $c = shift;

    $c->_load_profile;
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

    my $profile = $c->_load_profile;
    my $dtf = $c->crp->model('Course')->result_source->schema->storage->datetime_parser;
    my $days = $c->config->{course}->{age_when_advert_expires_days};
    my $advertised_list = [ $profile->courses(
        {
            published   => 1,
            canceled    => 0,
            start_date  => {'>', $dtf->format_datetime(DateTime->now()->subtract(days => $days))},
        },
        { order_by => {-asc => 'start_date'} },
    ) ];
    $c->stash(advertised_list => $advertised_list);
    my $draft_list = [ $profile->courses(
        { published   => 0 },
        { order_by => {-asc => 'start_date'} },
    ) ];
    $c->stash(draft_list => $draft_list);
    my $past_list = [ $profile->courses(
        {
            published   => 1,
            start_date  => {'<=', $dtf->format_datetime(DateTime->now()->subtract(days => $days))},
        },
        { order_by => {-asc => 'start_date'} },
    ) ];
    $c->stash(past_list => $past_list);
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

    my $profile = $c->_load_profile;
    my $validation = $c->validation;

    my $record = {
        instructor_id       => $profile->instructor_id,
        location            => $c->crp->trimmed_param('location'),
        latitude            => $c->crp->number_or_null($c->param('latitude')),
        longitude           => $c->crp->number_or_null($c->param('longitude')),
        venue               => $c->crp->trimmed_param('venue'),
        description         => $c->crp->trimmed_param('description'),
        start_date          => $c->_get_date_input($c->crp->trimmed_param('start_date')),
        time                => $c->crp->trimmed_param('time'),
        price               => $c->crp->trimmed_param('price'),
        session_duration    => $c->crp->trimmed_param('session_duration'),
        course_duration     => $c->crp->trimmed_param('course_duration'),
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

    my $profile = $c->_load_profile;
    my $config = $c->config->{course};
    $course->location($profile->location);
    $course->session_duration($config->{default_session_duration});
    $course->course_duration($config->{default_course_duration});
}

sub _display_course_editor_with {
    my $c = shift;
    my($course) = @_;

    my $profile = $c->_load_profile;
    $c->stash(site_profile => $profile);
    $c->stash('course_record', $course);
    $c->stash('edit_restriction', 'PUBLISHED') if $course->published;
}

sub _get_date_input {
    my $c = shift;
    my($date) = @_;

    my $parser = CRP::Util::DateParser->new(prefer_month_first_order => 1);
    $parser->parse($date);
    return undef unless $parser->parsed_ok;
    my $res;
    try {
        $res = DateTime->new(
            year        => $parser->year,
            month       => $parser->month,
            day         => $parser->day,
            time_zone   => 'UTC',
        );
    };
    return $res;
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
    my $profile = $c->_load_profile;
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

    my $course_id = $c->param('course_id');
    my $course = $c->crp->model('Course')->find({id => $course_id});
    die "You can't edit this course" unless $course && $course->is_cancelable_by_instructor($c->crp->logged_in_instructor_id);
    $c->stash('crp_session')->variable('course_id', $course_id);
    $c->stash('course_record', $course);
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
    my $data = {
        profile             => $c->_load_profile,
        url                 => $c->url_for('crp.membersite.home', slug => $c->stash('profile_record')->web_page_slug)->to_abs,
        email               => $c->stash('crp_session')->variable('email'),
        venue               => $course->venue,
        date                => $c->crp->format_date($course->start_date, 'stroke'),
        course_duration     => $course->course_duration,
        session_duration    => $course->session_duration,
        time                => $course->time,
        price               => $course->price,
        description         => $course->description,
        course_url          => $c->url_for('crp.membersite.course', slug => $c->stash('profile_record')->web_page_slug, course => $course->id)->to_abs,
    };
    $c->render_file(
        data                => $pdf_doc->fill_template($data),
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
    );
}

1;

