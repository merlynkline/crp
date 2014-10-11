package CRP::Test;
use Mojo::Base 'Mojolicious::Controller';

sub authenticate {
    my $self = shift;

    return 1 if $self->app->mode eq 'development';
    $self->reply->not_found;
    return 0;
}

sub welcome {
    my $self = shift;

    $self->render;
}

sub template {
    my $self = shift;

    my $template = $self->stash('template');
    $self->render(template => $template);
}

1;
