package CRP::Controller::Premium;
use Mojo::Base 'Mojolicious::Controller';

#  Premium content delivery. Auth process is designed such that:
#  - Most authorisation is by cookie, so it's quick
#  - New cookies are generated reasonably often so lockouts etc are effective
#  - Most access is through a URL that doesn't include the ID so sharing it won't work

use CRP::Util::WordNumber;
use CRP::Util::PremiumContent;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub content {
    my $c = shift;

    my $premium_content = $c->_get_premium_content_handler;

    if($premium_content->cookie && ($premium_content->is_authorised_id || $premium_content->cookie_id_matches)) {
        if($premium_content->cookie_dir_matches) {
            if($premium_content->cookie_expired) {
                $premium_content->generate_cookie;
                return $premium_content->show_access_page unless $premium_content->cookie;
            }
        }
        else {
            return $premium_content->show_not_found_page unless $premium_content->dir_exists;
            $premium_content->generate_cookie;
            return $premium_content->show_access_page unless $premium_content->cookie;
        }
        return $premium_content->redirect_to_authorised_path if $premium_content->id ne $premium_content->authorised_id;
    }
    else {
        $premium_content->generate_cookie;
        return $premium_content->show_access_page unless $premium_content->cookie;
        return $premium_content->redirect_to_authorised_path;
    }

    return $premium_content->send_content($premium_content);
}

sub _get_premium_content_handler {
    my $c = shift;

    my $subpath = $c->stash('subpath') // '';
    my($id, $path) = split('/', $subpath, 2);
    $id //= '';
    return CRP::Util::PremiumContent->new(
        c    => $c,
        dir  => $c->stash('dir'),
        id   => $id,
        path => $path,
    );
}

sub link_request {
    my $c = shift;

    my $premium_content = $c->_get_premium_content_handler;

    my $validation = $c->validation;
    $c->crp->validate_recaptcha($validation);
    $validation->required('email')->like(qr{^.+@.+[.].+});

    my @pages;
    if( ! $validation->has_error) {
        @pages = $premium_content->get_all_pages_for_email($c->param('email'));
        $validation->error(email => ["no_premium_available"]) unless @pages;
    }

    return $premium_content->show_access_page if $validation->has_error;

    $premium_content->send_email($c->param('email'), 'link_request', {pages => \@pages});
    $c->redirect_to($c->url_for('crp.premium.linkrequestsent', {dir => $premium_content->dir}));
}

sub link_request_sent {
    my $c = shift;

    my $premium_content = $c->_get_premium_content_handler;

    $premium_content->render_template('link_request_sent');
}

1;

