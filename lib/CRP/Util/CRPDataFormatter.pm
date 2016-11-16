package CRP::Util::CRPDataFormatter;

use strict;
use warnings;

use DateTime;
use CRP::Util::WordNumber;

sub format_data {
    my($c, $crp_data) = @_;

    my $data = {%$crp_data};

    _set_common_data($c, $data);

    my $profile = $data->{profile};
    _extract_crp_profile_data($c, $data);
    _extract_crp_qualification_data($c, $data, $profile);
    _extract_crp_course_data($c, $data, $profile);
    _extract_crp_instructor_course_data($c, $data, $profile);
    _set_invoice_data($c, $data);
    _set_demonstration_data($c, $data) if $profile && $profile->login->is_demo;
    _extract_attendee_data($c, $data);

    delete $data->{profile};
    delete $data->{course};

    return $data;
}

sub _set_common_data {
    my($c, $data) = @_;

    $data->{today} = $c->crp->format_date(DateTime->now(), 'long');
}

sub _set_invoice_data {
    my($c, $data) = @_;

    return unless $data->{profile};
    $data->{invoice_number} = _generate_invoice_number($data);
    if(exists $data->{course_type}) {
        $data->{invoice_line_1} = 'Training course';
        $data->{invoice_line_2} = $data->{course_type};
        my $price = $data->{price};
        $price =~ s/[^\d.]//g;
        $price .= '.00' if $price ne '' && $price !~ /\./;
        $data->{invoice_price}  = $price;
        
    }
}

sub _extract_crp_profile_data {
    my($c, $data) = @_;

    return unless $data->{profile};
    my $path = $c->crp->instructor_photo_location;
    my $name = $c->crp->name_for_instructor_photo($data->{profile}->instructor_id);
    $name = 'default.jpg' unless -r $c->crp->path_for_public_file("$path$name");
    $data->{profile_image} = $c->crp->path_for_public_file("$path$name");

    my $profile = $data->{profile};
    $data->{$_} = $profile->$_ foreach(qw(name postcode telephone mobile));

    my $phone_numbers = $profile->telephone;
    $phone_numbers .= ' / ' if $phone_numbers && $profile->mobile;
    $phone_numbers .= $profile->mobile // '';
    $data->{phone_numbers} = $phone_numbers;

    my $one_line_address = $profile->address // '';
    $one_line_address =~ s{\s*[\r\n]+\s*}{, }gsm;
    $one_line_address =~ s{^\s*|\s*$}{}g;
    $data->{one_line_address} = $one_line_address;

    $data->{url} = $c->url_for('crp.membersite.home', slug => $profile->web_page_slug)->to_abs,
    $data->{url} =~ s{.+?://}{};

    my $signature = '-' . CRP::Util::WordNumber::encipher($profile->id);
    $data->{signature} = $signature;
    $data->{signature_url} = $c->url_for('crp.membersite.certificate', slug => $signature)->to_abs;
    $data->{signature_date} = $c->crp->format_date(_certificate_date($profile->login->create_date), 'cert');
}

sub _extract_crp_qualification_data {
    my($c, $data, $profile) = @_;

    $data->{_mark_trainee} = 1;
    return unless $profile;
    my $qualifications_desc = '';
    my @qualifications = $profile->qualifications;
    if(@qualifications) {
        my $most_recent_date;
        foreach my $qualification (@qualifications) {
            next if $qualification->is_trainee;
            $qualifications_desc .= $qualification->qualification->qualification . "\n";
            $most_recent_date = $qualification->passed_date if ! $most_recent_date || $qualification->passed_date > $most_recent_date;
        }
        $data->{signature_date} = $c->crp->format_date(_certificate_date($most_recent_date), 'cert') if $most_recent_date;
    }
    if($qualifications_desc) {
        $data->{_mark_trainee} = 0;
        $data->{qualifications} = substr $qualifications_desc, 0, -1;
        $data->{status} = "Qualified Instructor";
    }
    else {
        $data->{qualifications} = "TRAINEE";
        $data->{status} = "TRAINEE";
    }
}

sub _certificate_date {
    my($signup_date) = @_;

    my $earliest = DateTime->now()->subtract(years => 1);
    $signup_date = $signup_date->add(years => 1) while $signup_date < $earliest;
    return $signup_date;
}

sub _extract_crp_instructor_course_data {
    my($c, $data, $profile)  = @_;

    return unless $data->{instructor_course};

    my $course = $data->{instructor_course};
    $data->{$_} = $course->$_ foreach(qw(venue duration price description));
    $data->{course_type} = $course->course_type->description;
    $data->{date} = $c->crp->format_date($course->start_date, 'stroke');
    $data->{_mark_trainee} = 0;
}

sub _extract_crp_course_data {
    my($c, $data, $profile)  = @_;

    return unless $data->{course};

    my $course = $data->{course};
    $data->{$_} = $course->$_ foreach(qw(venue course_duration session_duration time price description));

    $data->{price}      .= ' including a copy of the book, The Mouse\'s House.' unless $course->book_excluded;
    $data->{date}       = $c->crp->format_date($course->start_date, 'stroke');
    $data->{weekday}    = $c->crp->format_date($course->start_date, 'weekday');
    $data->{course_url} = $c->url_for(
        'crp.membersite.course',
        slug => $profile->web_page_slug,
        course => $course->id
    )->to_abs;
    $data->{course_type}   = $course->course_type->description;
    $data->{_mark_trainee} = 0;
}

sub _set_demonstration_data {
    my($c, $data) = @_;

    $data->{email} = '(Demonstration email)';
    $data->{phone_numbers} = '(Demonstration phone)';
    $data->{one_line_address} = '(Demonstration postal address)';
    $data->{_is_demo} = 1;
}

sub _generate_invoice_number {
    my($data) = @_;

    return CRP::Util::WordNumber::encipher($data->{profile}->id) . '.' . CRP::Util::WordNumber::encipher(localtime);
}

sub _extract_attendee_data {
    my($c, $data) = @_;

    return unless my $attendee = $data->{attendee};
    return if $data->{profile};

    $data->{_mark_trainee} = 0;
    $data->{$_} = $attendee->$_ foreach(qw(name email organisation_name organisation_address organisation_telephone organisation_postcode));
}

1;

