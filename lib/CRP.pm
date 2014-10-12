package CRP;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  my $config = $self->plugin('Config');

  $self->secrets([$config->{secret}]);
  $self->sessions->cookie_name($config->{session_cookie_name});

  $self->helper(stash_list => sub {
      # Get a value from the stash, always returning a listref
      my $self = shift;
      my $var_value = $self->stash($_[0]);
      return [] unless $var_value;
      $var_value = [ $var_value ] unless ref $var_value;
      return $var_value;
  });

  # Router
  my $r = $self->routes;

  $r->get('/')->to('main#welcome');
  $r->any('/main/register_interest')->to('main#register_interest');
  $r->get('/page/*page')->to('main#page');

  my $tests=$r->under('/test')->to('test#authenticate');
  $tests->get('/')->to('test#welcome');
  $tests->get('/template/*template')->to('test#template');
}

1;
