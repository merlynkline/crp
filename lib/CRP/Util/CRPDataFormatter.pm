package CRP::Util::CRPDataFormatter;

use strict;
use warnings;

use DateTime;
use CRP::Util::WordNumber;

sub format_data {
    my($c, $crp_data) = @_;

    my $data = {%$crp_data};
    my $profile = $data->{profile};
    _extract_crp_profile_data($c, $data);
    _extract_crp_course_data($c, $data, $profile);
    _set_demonstration_data($c, $data) if $profile->login->is_demo;

    delete $data->{profile};
    delete $data->{course};

    return $data;
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

    my $one_line_address = $profile->address;
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

sub _certificate_date {
    my($signup_date) = @_;

    my $earliest = DateTime->now()->subtract(years => 1);
    $signup_date = $signup_date->add(years => 1) while $signup_date < $earliest;
    return $signup_date;
}

sub _extract_crp_course_data {
    my($c, $data, $profile)  = @_;

    return unless $data->{course};

    my $course = $data->{course};
    $data->{$_} = $course->$_ foreach(qw(venue course_duration session_duration time price description));

    $data->{date}       = $c->crp->format_date($course->start_date, 'stroke');
    $data->{weekday}    = $c->crp->format_date($course->start_date, 'weekday');
    $data->{course_url} = $c->url_for(
        'crp.membersite.course',
        slug => $profile->web_page_slug,
        course => $course->id
    )->to_abs,
}

sub _set_demonstration_data {
    my($c, $data) = @_;

    $data->{email} = '(Demonstration email)';
    $data->{phone_numbers} = '(Demonstration phone)';
    $data->{one_line_address} = '(Demonstration postal address)';
    $data->{_is_demo} = 1;
}

1;

