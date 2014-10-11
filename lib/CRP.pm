package CRP;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  my $config = $self->plugin('Config');

  $self->secrets([$config->{secret}]);
  $self->sessions->cookie_name($config->{session_cookie_name});

  # Router
  my $r = $self->routes;

  $r->get('/')->to('main#welcome');
  $r->get('/page/*page')->to('main#page');

  my $tests=$r->under('/test')->to('test#authenticate');
  $tests->get('/')->to('test#welcome');
  $tests->get('/template/*template')->to('test#template');
}

1;
