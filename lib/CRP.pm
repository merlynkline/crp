package CRP;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::CSRFProtect;
use Mojolicious::Plugin::RenderFile;
use DBIx::Connector;

use CRP::Helper::Main;
use CRP::Model::Schema;
use CRP::Util::Session;

# This method will run once at server start
sub startup {
    my $self = shift;

    my $config = $self->plugin('Config');
    $self->plugin('CSRFProtect', on_error => \&_csrf_error_handler);
    $self->plugin('CRP::Helper::Main');
    $self->plugin('RenderFile');
    $self->plugin(mail => $config->{mail});
    $self->secrets([$config->{secret}]);
    $self->sessions->cookie_name($config->{session}->{cookie_name});

    push @{$self->app->commands->namespaces}, 'CRP::Command';

    $self->app->types->type(csv => 'text/csv;charset=UTF-8');

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
    $logged_in->any('page/*page')->to('members#page')->name('crp.members.page');
    $logged_in->any('get_pdf/:pdf')->to('members#get_pdf')->name('crp.members.get_pdf');
    $logged_in->any('find_enquiries')->to('members#find_enquiries')->name('crp.members.find_enquiries');
    
    my $member_site = $r->under('/me/:slug')->to('member_site#identify');
    $member_site->any('/')->to('/')->to('member_site#welcome')->name('crp.membersite.home');

    my $tests = $r->under('/test')->to('test#authenticate');
    $tests->get('/')->to('test#welcome');
    $tests->get('/template/*template')->to('test#template');
    $tests->get('/list_pdfs')->to('test#list_pdfs');
    $tests->get('/pdf/*pdf')->to('test#pdf');

    $self->app->hook(before_dispatch => \&_before_dispatch);
    $self->app->hook(after_dispatch => \&_after_dispatch);
}

sub _before_dispatch {
    my $c = shift;

    $c->stash(crp_session => CRP::Util::Session->new(mojo => $c));
    $c->stash(logged_in => $c->crp->logged_in_instructor_id);
}

sub _after_dispatch {
    my $c = shift;

    $c->stash('crp_session')->write();
}

sub _csrf_error_handler {
    my $c = shift;

    $c->render(template => 'csrf_violation', status => 403 );
}

1;

