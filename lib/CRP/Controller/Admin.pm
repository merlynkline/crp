package CRP::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;

use Try::Tiny;
use DateTime;
use CRP::Util::DateParser;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $c = shift;

    return 1 if $c->stash('login_record')->is_administrator;
    $c->render(text => "Sorry - you aren't authorised to see this page", status => 403);
    return 0;
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    my $days = $c->config->{course}->{age_when_advert_expires_days};
    $c->stash(instructor_count          => $c->crp->model('Profile')->search_live_profiles->count);
    $c->stash(draft_courses_count       => $c->crp->model('Course')->get_draft_set->count);
    $c->stash(advertised_courses_count  => $c->crp->model('Course')->get_advertised_set($days)->count);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');
    $c->stash('page', $page);

    $c->render(template => "admin/pages/$page");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub instructor_search {
    my $c = shift;

    my $matches;
    if($c->req->method eq 'POST') {
        my $validation = $c->validation;
        $validation->required('name');
        my $name = $c->crp->trimmed_param('name');
        $name =~ s{^ [%\s]+ | [\s%]+ $}{}gsmx; # Prevent match-all searches
        $validation->error(name => ['like']) unless $name;
        if( ! $validation->has_error) {
            if($name =~ m{^-?(\d+)$}) {
                return $c->redirect_to('crp.membersite.certificate', slug => "-$1");
            }
            else {
                $c->stash(search_key => $name);
                $matches = $c->_find_instructors($name);
                if($matches && @$matches == 1) {
                    return $c->redirect_to('crp.membersite.home', slug => $matches->[0]->web_page_slug);
                }
            }
        }
    }
    return $c->page('instructor_search', matches => $matches);
}

sub _find_instructors {
    my $c = shift;
    my($search_key) = @_;

    my @matches = $c->crp->model('Profile')->search_live_profiles(
        {'lower(name)' => { like => lc "%$search_key%"}},
        {order_by => {-asc => 'lower(name)'}},
    );
    return \@matches if @matches;
    return;
}


1;

