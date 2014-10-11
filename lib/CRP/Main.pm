package CRP::Main;
use Mojo::Base 'Mojolicious::Controller';

sub welcome {
  my $self = shift;

  $self->render;
}

sub page {
  my $self = shift;

  my $page = $self->stash('page');

  $self->render(template => "main/pages/$page");
}

1;
