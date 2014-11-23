package CRP::Controller::LoggedIn;
use Mojo::Base 'Mojolicious::Controller';

sub authenticate {
    my $self = shift;

    my $logged_in_id = $self->stash('crp_session')->variable($self, 'instructor_id');
    if($logged_in_id) {
        my $login_record = $self->crp->model('Login')->find($logged_in_id);
        if($login_record) {
            $self->stash('login_record', $login_record);
            return $self->_check_if_interstitial_needed if $login_record;
        }
    }

    $self->_show_interstitial($self->url_for('/login'), {login_reason => 'logged_out'});
    return 0;
}

sub _show_interstitial {
    my $self = shift;
    my($url, $session_vars) = @_;

    my $destination = $self->stash('crp_session')->variable($self, 'interstitial_destination');
    unless($destination) {
        if($self->req->method eq 'GET') {
            $destination = $self->req->url->to_string;
        }
        else {
            $destination = 'crp.logged_in_default';
        }
        $self->stash('crp_session')->variable($self, 'interstitial_destination', $destination);
    }

    if($session_vars) {
        while(my($var, $value) = each %$session_vars) {
            $self->stash('crp_session')->variable($self, $var, $value);
        }
    }

    $self->redirect_to($url);
}

sub _check_if_interstitial_needed {
    my $self = shift;

    if( ! $self->stash('login_record')->password_hash
        && $self->current_route ne 'crp.set_password'
    ) {
        $self->_show_interstitial($self->url_for('crp.set_password'));
        return 0;
    }

    return 1;
}


sub welcome {
    my $self = shift;

    $self->render(text => 'Logged in: id=' . $self->stash('crp_session')->variable($self, 'instructor_id'));
}

1;
