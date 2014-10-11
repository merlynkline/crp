package CRP::Example;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub welcome {
  my $self = shift;

  my $cookie = $self->cookie($self->config('session_cookie_name')) // 'NONE';

  my $var = $self->session('var') // 'EMPTY';

  $self->session({ var => 'thing' });

  use Data::Dumper;
  $self->app->log->debug(Dumper(\%ENV));

  # Render template "example/welcome.html.ep" with message
  $self->render(
    message => "Welcome to the Mojolicious real-time web framework! cookie='$cookie' var='$var'");
}

1;
