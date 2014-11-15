package CRP;
use Mojo::Base 'Mojolicious';
use DBIx::Connector;

use CRP::Helper::Main;
use CRP::Model::Schema;

# This method will run once at server start
sub startup {
    my $self = shift;

    my $config = $self->plugin('Config');
    $self->plugin('CRP::Helper::Main');
    $self->plugin(mail => $config->{mail});
    $self->secrets([$config->{secret}]);
    $self->sessions->cookie_name($config->{session_cookie_name});

    push @{$self->app->commands->namespaces}, 'CRP::Command';

    # Router
    my $r = $self->routes;

    $r->get('/')->to('main#welcome');
    $r->any('/update_registration')->to('main#update_registration');
    $r->any('/main/contact')->to('main#contact');
    $r->any('/main/register_interest')->to('main#register_interest');
    $r->any('/main/resend_confirmation')->to('main#resend_confirmation');
    $r->get('/page/*page')->to('main#page');

    my $tests=$r->under('/test')->to('test#authenticate');
    $tests->get('/')->to('test#welcome');
    $tests->get('/template/*template')->to('test#template');
}


1;

