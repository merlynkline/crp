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
        return $c->render(satus => 404);
    }

    $c->stash(site_profile => $profile);
    return 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    $c->render;
}

1;

