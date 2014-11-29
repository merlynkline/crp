package CRP;
use Mojo::Base 'Mojolicious';
use DBIx::Connector;

use CRP::Helper::Main;
use CRP::Model::Schema;
use CRP::Util::Session;

# This method will run once at server start
sub startup {
    my $self = shift;

    my $config = $self->plugin('Config');
    $self->plugin('CRP::Helper::Main');
    $self->plugin(mail => $config->{mail});
    $self->secrets([$config->{secret}]);
    $self->sessions->cookie_name($config->{session}->{cookie_name});

    push @{$self->app->commands->namespaces}, 'CRP::Command';

    # Router
    my $r = $self->routes;

    $r->get('/')->to('main#welcome');
    $r->any('/update_registration')->to('main#update_registration');
    $r->any('/main/contact')->to('main#contact');
    $r->any('/main/register_interest')->to('main#register_interest');
    $r->any('/main/resend_confirmation')->to('main#resend_confirmation');
    $r->any('/login')->to('logged_in#login')->name('crp.login');;
    $r->any('/logout')->to('logged_in#logout')->name('crp.logout');;
    $r->get('/page/*page')->to('main#page');
    $r->any('/otp')->to('logged_in#otp');
    $r->get('/otp/*otp')->to('logged_in#otp');

    my $logged_in = $r->under('/instructor')->to('logged_in#authenticate');
    $logged_in->get('/')->to('members#welcome')->name('crp.logged_in_default');
    $logged_in->any('/set_password')->to('logged_in#set_password')->name('crp.set_password');
    $logged_in->any('/profile')->to('members#profile')->name('crp.members.profile');

    my $tests = $r->under('/test')->to('test#authenticate');
    $tests->get('/')->to('test#welcome');
    $tests->get('/template/*template')->to('test#template');

    $self->app->hook(before_dispatch => \&_before_dispatch);
    $self->app->hook(after_dispatch => \&_after_dispatch);
}

sub _before_dispatch {
    my $c = shift;

    $c->stash(crp_session => CRP::Util::Session->new(mojo => $c));
    $c->stash(logged_in => $c->stash('crp_session')->variable('instructor_id'));
}

sub _after_dispatch {
    my $c = shift;

    $c->stash('crp_session')->write();
}

1;

