package CRP::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';

sub welcome {
  my $c = shift;

  $c->render;
}

sub page {
  my $c = shift;

  my $page = $c->stash('page');

  $c->render(template => "main/pages/$page");
}

sub register_interest {
  my $c = shift;

  $c->stash('page', 'carers');
  my $validation = $c->validation;
  $validation->required('email')->like(qr{^.+@.+[.].+});
  return $c->page if($validation->has_error);

  my $email = $c->param('email');


}

1;
