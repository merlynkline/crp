package CRP::Controller::Members;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    my $profile = $c->_load_profile;
    $c->stash(incomplete_profile => ! $profile->is_complete);
    $c->render;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');
    $c->stash('page', $page);

    $c->render(template => "members/pages/$page");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub profile {
    my $c = shift;

    my $profile = $c->_load_profile;

    if($c->req->method eq 'POST') {
        my $validation = $c->validation;

        foreach my $field (qw(name address postcode telephone mobile blurb)) {
            eval { $profile->$field($c->param($field)); };
            my $error = $@;
            if($error =~ m{^CRP::Util::Types::(.+?) }) {
                $validation->error($field => ["invalid_column_$1"]);
            }
            else {
                die $error if $error;
            }
        }
        if($validation->has_error) {
            $c->stash(msg => 'fix_errors');
        }
        else {
            $profile->update;
            $c->stash(msg => 'profile_update');
        }
    }

    $c->render;
}

sub _update_profile {
    my $c = shift;

}

sub _load_profile {
    my $c = shift;

    my $instructor_id = $c->stash('crp_session')->variable('instructor_id');
    my $profile = $c->crp->model('Profile')->find_or_create({instructor_id => $instructor_id});
    $c->stash('profile_record', $profile);
    return $profile;
}


1;

