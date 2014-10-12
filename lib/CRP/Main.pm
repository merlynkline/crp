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

sub register_interest {
  my $self = shift;

  my $email = $self->param('email');

  $self->stash('page', 'carers');
  $self->stash('errors', 'NO_EMAIL');
  return $self->page;


}

1;
