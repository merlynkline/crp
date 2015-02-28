package CRP::Util::CRPDataFormatter;

use strict;
use warnings;

sub format_data {
    my($c, $crp_data) = @_;

    my $data = {%$crp_data};
    my $profile = $data->{profile};
    _extract_crp_profile_data($c, $data);
    _extract_crp_course_data($c, $data, $profile);

    delete $data->{profile};
    delete $data->{course};

    return $data;
}

sub _extract_crp_profile_data {
    my($c, $data) = @_;

    return unless $data->{profile};

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

1;

