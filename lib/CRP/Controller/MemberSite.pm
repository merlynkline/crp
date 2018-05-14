package CRP::Controller::MemberSite;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;

use CRP::Util::WordNumber;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub identify {
    my $c = shift;
    my $slug = $c->stash('slug');

    my $profile;
    if($slug =~ m{^\d+$}) {
        $profile = $c->crp->model('Profile')->find($slug);
    }
    elsif($slug =~ m{^-(.+)$}) {
        my $id = CRP::Util::WordNumber::decode_number($1);
        $profile = $c->crp->model('Profile')->find($id);
    }
    else {
        $profile = $c->crp->model('Profile')->find({web_page_slug => $slug});
    }
    unless($profile) {
        $c->render(template => 'member_site/member_not_found', status => 404);
        return 0;
    }

    $c->stash(site_profile => $profile);
    return 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    my $profile = $c->stash('site_profile');
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
    my $instructors_advertised_list = [ $profile->instructors_courses(
        {
            published   => 1,
            canceled    => 0,
            start_date  => {'>', $dtf->format_datetime(DateTime->now())},
        },
        { order_by => {-asc => 'start_date'} },
    ) ];
    $c->stash(instructors_advertised_list => $instructors_advertised_list);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub certificate {
    my $c = shift;

    my $profile = $c->stash('site_profile');
    $c->stash(signature_id => '-' . CRP::Util::WordNumber::encipher($profile->instructor_id));
    $c->stash(today => $c->crp->format_date(DateTime->now(), 'long'));
}

sub _get_published_course {
    my $c = shift;
    my($course_id) = @_;

    my $course = $c->crp->model('Course')->find($course_id);
    return $course if
        $course
        && $course->instructor_id == $c->stash('site_profile')->instructor_id
        && $course->published;
    return;
}

sub _stash_published_course_and_past_flag_or_404 {
    my $c = shift;

    my $course = $c->_get_published_course($c->stash('course'));
    unless($course) {
        $c->reply->not_found;
        return undef;
    }
    $c->stash(course => $course);
    my $days = $c->config->{course}->{age_when_advert_expires_days};
    $c->stash(past_course => $course->start_date < DateTime->now()->subtract(days => $days));
    return 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub course {
    my $c = shift;

    return unless $c->_stash_published_course_and_past_flag_or_404;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDFMarkUp;
use CRP::Util::CRPDataFormatter;
sub booking_form {
    my $c = shift;

    return unless $c->_stash_published_course_and_past_flag_or_404;
    my $code = $c->stash('course')->course_type->code;
    my $pdf = $c->app->home->rel_file("pdfs/members/booking_form-$code.pdf")->to_string;
    $pdf = $c->app->home->rel_file('pdfs/members/booking_form.pdf')->to_string unless -f $pdf;
    my $pdf_doc = CRP::Util::PDFMarkUp->new(file_path => $pdf);
    my $data = CRP::Util::CRPDataFormatter::format_data($c, {
            profile => $c->stash('site_profile'),
            course  => $c->stash('course'),
            email   => $c->stash('site_profile')->login->email,
        });
    $c->render_file(
        data                => $pdf_doc->fill_template($data),
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
        filename            => $pdf_doc->filename,
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub mencap_form {
    my $c = shift;

    my $pdf = $c->app->home->rel_file("pdfs/members/mencap.pdf")->to_string;
    my $pdf_doc = CRP::Util::PDFMarkUp->new(file_path => $pdf);
    my $data = CRP::Util::CRPDataFormatter::format_data($c, {
            profile => $c->stash('site_profile'),
            email   => $c->stash('site_profile')->login->email,
        });
    $c->render_file(
        data                => $pdf_doc->fill_template($data),
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
        filename            => $pdf_doc->filename,
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub book_online {
    my $c = shift;

    return unless $c->_stash_published_course_and_past_flag_or_404;
    $c->render(template => 'member_site/book_online');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub send_booking {
    my $c = shift;

    my $validation = $c->validation;
    $validation->required('050_email')->like(qr{^.+@.+[.].+});
    return $c->book_online if($validation->has_error);

    my %info;
    foreach my $param (@{$c->req->params->names}) {
        next unless $param =~ /^\d\d\d_/;
        $info{$param} =  Mojo::Util::xml_escape($c->crp->trimmed_param($param) // '');
        $info{$param} =~ s{\n}{<br \\>\n}g;
    }
    $c->mail(
        to              => $c->crp->email_to($c->app->config->{email_addresses}->{contact_form}),
        template        => 'member_site/email/course_booking_notification',
        info            => {%info, '000_instructor' => $c->stash('site_profile')->login->email},
    );
    $c->mail(
        reply_to        => $c->crp->email_decorated($c->crp->trimmed_param('050_email'), $c->crp->trimmed_param('040_name')),
        to              => $c->crp->email_to($c->stash('site_profile')->login->email),
        template        => 'member_site/email/course_booking_form',
        info            => \%info,
    );
    $c->redirect_to('/page/course_booked');
}

1;

