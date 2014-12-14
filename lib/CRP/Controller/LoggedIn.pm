package CRP::Controller::LoggedIn;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;
use CRP::Util::WordNumber;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $c = shift;

    my $logged_in_id = $c->crp->logged_in_instructor_id;
    if($logged_in_id) {

        my $login_record = $c->crp->model('Login')->find($logged_in_id);
        if($login_record) {
            $c->stash('login_record', $login_record);
            return $c->_check_if_interstitial_needed if $login_record;
        }
    }

    $c->_show_interstitial($c->url_for('crp.login'), {login_reason => 'LOGIN_REQUIRED'});
    return 0;
}

sub _show_interstitial {
    my $c = shift;
    my($url, $session_vars) = @_;

    my $destination = $c->stash('crp_session')->variable('interstitial_destination');
    unless($destination) {
        if($c->req->method eq 'GET') {
            $destination = $c->req->url->to_string;
        }
        else {
            $destination = 'crp.logged_in_default';
        }
        $c->stash('crp_session')->variable('interstitial_destination', $destination);
    }

    if($session_vars) {
        while(my($var, $value) = each %$session_vars) {
            $c->stash('crp_session')->variable($var, $value);
        }
    }

    $c->redirect_to($url);
}

sub _check_if_interstitial_needed {
    my $c = shift;

    if( ! $c->stash('login_record')->password_hash
        && $c->current_route ne 'crp.set_password'
    ) {
        $c->_show_interstitial($c->url_for('crp.set_password'));
        return 0;
    }

    return 1;
}

sub _redirect_to_interstitial_continuation_or_url {
    my $c = shift;
    my($url) = @_;

    my $destination = $c->stash('crp_session')->variable('interstitial_destination');
    if($destination) {
        $c->stash('crp_session')->variable('interstitial_destination', undef);
        $url = $destination;
    }

    return $c->redirect_to($url);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub login {
    my $c = shift;

    return $c->_show_login unless $c->req->method eq 'POST';

    my $email       = $c->crp->trimmed_param('email');
    my $password    = $c->crp->trimmed_param('password');
    my $auto_login  = $c->param('auto_login');
    my $forgotten   = $c->param('forgotten');

    my $validation = $c->validation;
    $validation->required('email')->like(qr{^.+@.+[.].+});
    my $login_record = $c->_case_insensitive_login_email_find($email) unless $validation->has_error;
    $validation->error(email => ['no_such_email']) unless $login_record;
    return $c->_show_login if($validation->has_error);

    return $c->_send_otp($login_record) if $forgotten;

    $validation->required('password');
    unless($validation->has_error) {
        if($c->_password_hash($password, $login_record->id) ne $login_record->password_hash) {
            $validation->error(password => ['incorrect_password']);
            sleep 3;
        }
    }
    return $c->_show_login if $validation->has_error;

    $c->_do_login($login_record, $auto_login);
}

sub _show_login {
    my $c = shift;

    $c->stash('reason', $c->stash('crp_session')->variable('login_reason') // '');
    $c->render(template => "logged_in/login");
}

sub _case_insensitive_login_email_find {
    my $c = shift;
    my($email) = @_;

    return $c->crp->model('Login')->find({'lower(me.email)' => lc $email});
}

sub _send_otp {
    my $c = shift;
    my($login_record) = @_;

    my $identifier = CRP::Util::WordNumber::encode_number($login_record->id);
    my $otp = unpack "H32", Mojo::Util::md5_bytes CRP::Util::WordNumber::encode_number(
        int(rand() * 100000 + time % 10000 + $$)
    );
    my $hours = $c->app->config->{login}->{otp_lifetime};
    my $email_info = {
        identifier          => "$identifier/$otp",
        otp_page            => $c->url_for("/otp/$identifier/$otp")->to_abs(),
        general_otp_page    => $c->url_for('/otp')->to_abs(),
        lifetime            => $hours,
    };
    $c->mail(
        to          => $c->crp->email_to($login_record->email),
        template    => 'main/email/otp',
        info        => $email_info,
    );

    $login_record->otp_expiry_date(DateTime->now()->add(hours => $hours));
    $login_record->otp_hash($otp);
    $login_record->update();

    $c->redirect_to($c->url_for('/otp')->query(email => $login_record->email));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub otp {
    my $c = shift;

    my $otp = $c->stash('otp') || $c->crp->trimmed_param('otp');
    return $c->render(template => 'logged_in/otp') unless $otp;

    my $validation = $c->validation;
    $validation->error(otp => ['like']) unless $otp =~ m{[a-z0-9-]+/[a-f0-9]{32,32}}i;
    return $c->render(template => 'logged_in/otp') if($validation->has_error);

    my($identifier, $hash) = split '/', $otp;
    my $id = CRP::Util::WordNumber::decode_number($identifier);
    my $login_record = $c->crp->model('Login')->find($id);
    unless($login_record
      && ($login_record->otp_hash // '') eq $hash
      && $login_record->otp_expiry_date > DateTime->now) {
        $validation->error(otp => ['incorrect_password']);
        sleep 3;
    }
    return $c->render(template => 'logged_in/otp') if($validation->has_error);
    
    $login_record->otp_expiry_date(undef);
    $login_record->otp_hash(undef);
    $login_record->update();

    $c->_do_login($login_record);
}

sub _do_login {
    my $c = shift;
    my($login_record, $auto_login) = @_;

# TODO: handle auto-login flag
    my $crp_session = $c->stash('crp_session');
    my $destination = $crp_session->variable('interstitial_destination');
    $crp_session->create_new();
    $crp_session->variable(instructor_id => $login_record->id);
    $crp_session->variable(email => $login_record->email);
    $crp_session->variable(login_reason => undef);
    $crp_session->variable(interstitial_destination => $destination) if $destination;
    $c->_redirect_to_interstitial_continuation_or_url('crp.logged_in_default');
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    $c->render;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub set_password {
    my $c = shift;

    if($c->req->method ne 'POST') {
        my $reason = '';
        $reason = 'NOT_SET' if ! $c->stash('login_record')->password_hash;
        $c->stash('reason', $reason);
        return $c->render(template => "logged_in/pages/set_password");
    }

    my $validation = $c->validation;
    my $pass1 = $c->crp->trimmed_param('pass1') // '';
    $validation->required('pass1');
    $validation->error(pass1 => ['password_bad']) if ! _is_good_password($pass1);
    my $pass2 = $c->crp->trimmed_param('pass2') // '';
    $validation->required('pass2');
    $validation->error(pass2 => ['password_mismatch']) if $pass2 ne $pass1;
    return $c->render(template => "logged_in/pages/set_password") if($validation->has_error);

    my $login_record = $c->stash('login_record');
    $login_record->password_hash($c->_password_hash($pass1, $c->crp->logged_in_instructor_id));
    $login_record->update();

    $c->_redirect_to_interstitial_continuation_or_url(
        $c->url_for('crp.logged_in_default')->query(msg => 'password_set')
    );
}

sub _is_good_password {
    my($password) = @_;

    $password = uc $password;
    return 0 if length $password < 6;
    return 0 if $password eq 'PASSWORD';
    return 0 if $password eq substr($password, 0, 1) x length $password;
    return 1;
}

sub _password_hash {
    my $c = shift;
    my($key, $instructor_id) = @_;

    $key = uc $key . $c->app->secrets->[0] . $instructor_id;
    return unpack "H32", Mojo::Util::md5_bytes $key;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub logout {
    my $c = shift;

    my $crp_session = $c->stash('crp_session');
    $crp_session->clear();
    $c->redirect_to('/');
}

1;

