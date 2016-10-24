package CRP::Controller::Premium;
use Mojo::Base 'Mojolicious::Controller';

use CRP::Util::WordNumber;
use CRP::Util::PremiumContent;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub content {
    my $c = shift;

    my $premium_content = CRP::Util::PremiumContent->new(
        c    => $c,
        dir  => $c->stash('dir'),
        id   => $c->stash('id'),
        path => $c->stash('path'),
    );

    if($premium_content->cookie && ($c->stash('id') eq $premium_content->authorised_id || $premium_content->cookie_id_matches)) {
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

1;

