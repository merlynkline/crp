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
    $c->render;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub certificate {
    my $c = shift;

    my $profile = $c->stash('site_profile');
    $c->stash(signature_id => '-' . CRP::Util::WordNumber::encipher($profile->instructor_id));
    $c->stash(today => $c->crp->format_date(DateTime->now(), 'long'));
    $c->render(template => 'member_site/certificate');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub course {
    my $c = shift;
    my $course_id = $c->stash('course');

    my $course = $c->crp->model('Course')->find($course_id);
    return $c->reply->not_found unless
        $course
        && $course->instructor_id == $c->stash('site_profile')->instructor_id
        && $course->published;

    $c->stash(course => $course);
    my $days = $c->config->{course}->{age_when_advert_expires_days};
    $c->stash(past_course => $course->start_date < DateTime->now()->subtract(days => $days));
}

1;

