package CRP::Controller::LoggedIn;
use Mojo::Base 'Mojolicious::Controller';

sub authenticate {
    my $self = shift;

    return 1 if $self->stash('crp_session')->variable($self, 'instructor_id');
    $self->render(text => 'You must log in first');
    return 0;
}

sub welcome {
    my $self = shift;

    $self->render(text => 'Logged in: id=' . $self->stash('crp_session')->variable($self, 'instructor_id'));
}

1;
