package CRP::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;

use Try::Tiny;
use DateTime;
use CRP::Util::DateParser;
use CRP::Util::WordNumber;

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
    $c->stash(past_courses_count        => $c->crp->model('Course')->get_past_set($days)->count);
    $c->render(template => "admin/welcome");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');
    $c->stash('page', $page);

    $c->render(template => "admin/pages/$page", @_);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub find_account {
    my $c = shift;

    if($c->req->method eq 'POST') {
        my $validation = $c->validation;
        $validation->required('query');
        my $query = $c->crp->trimmed_param('query');
        $query =~ s{^ [%\s]+ | [\s%]+ $}{}gsmx; # Prevent match-all searches
        $validation->error(query => ['like']) unless $query;
        return $c->_find_account_results($query) if( ! $validation->has_error);
    }
    return $c->welcome;
}

sub _find_account_results {
    my $c = shift;
    my($query) = @_;

    my $matches;
    if($query =~ m{^-?(\d+)$}) {
        my $id = CRP::Util::WordNumber::decode_number($1);
        return $c->redirect_to($c->url_for('crp.admin.show_account')->query(id => $id)) if $id;
    }
    if($query) {
        $c->stash(search_key => $query);
        $matches = $c->_find_acounts($query);
        if($matches && @$matches == 1) {
            $c->flash(msg => 'single_match');
            return $c->redirect_to($c->url_for('crp.admin.show_account')->query(id => $matches->[0]->id));
        }
    }
    return $c->page('find_account_results', matches => $matches);
}

sub _find_acounts {
    my $c = shift;
    my($search_key) = @_;

    my @matches = $c->crp->model('Login')->search(
        [
            {'lower(profile.name)' => { like => lc "%$search_key%"}},
            {'lower(email)' => { like => lc "%$search_key%"}},
        ],
        {
            join => 'profile',
            order_by => {-asc => 'lower(email)'}
        },
    );

    return \@matches if @matches;
    return;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub show_account {
    my $c = shift;

    my $id = $c->param('id') || shift || return $c->welcome;
    my $login = $c->crp->model('Login')->find($id) || return $c->welcome;
    my $days = $c->config->{course}->{age_when_advert_expires_days};
    my $profile = $login->profile;
    $c->stash(login => $login);
    if($profile) {
        $c->stash(
            profile_record            => $profile,
            draft_courses_count       => $profile->courses->get_draft_set->count,
            advertised_courses_count  => $profile->courses->get_advertised_set($days)->count,
            past_courses_count        => $profile->courses->get_past_set($days)->count,
        );
    }
    return $c->page('show_account');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub create_account {
    my $c = shift;

    if($c->req->method eq 'POST') {
        my $email = $c->crp->trimmed_param('email') || return $c->welcome;
        my $validation = $c->validation;
        $validation->required('email')->like(qr{^.+@.+[.].+});
        my $login_record;
        $login_record = $c->crp->model('Login')->find({'lower(me.email)' => lc $email}) unless $validation->has_error;
        $validation->error(email => ['duplicate_email']) if $login_record;
        return $c->welcome if $validation->has_error;

        $login_record = $c->crp->model('Login')->create({email => $email});
        $c->flash(msg => 'account_create');
        return $c->redirect_to($c->url_for('crp.admin.show_account')->query(id => $login_record->id));
    }
    return $c->page('show_account');
}

1;

