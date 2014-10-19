package CRP;
use Mojo::Base 'Mojolicious';
use DBIx::Connector;
use CRP::Model::Schema;

# This method will run once at server start
sub startup {
    my $self = shift;

    push @{$self->app->commands->namespaces}, 'CRP::Command';

    my $config = $self->plugin('Config');

    $self->secrets([$config->{secret}]);
    $self->sessions->cookie_name($config->{session_cookie_name});

    # Get a value from the stash, always returning a listref
    $self->helper(stash_list => sub {
            my $self = shift;
            my $var_value = $self->stash($_[0]);
            return [] unless $var_value;
            $var_value = [ $var_value ] unless ref $var_value;
            return $var_value;
        });

    # database connection prefork save with DBIx::Connector
    my $connector = CRP::Model::Schema::build_connector($config->{database});
    $self->helper(
        model => sub {
            my ($self, $resultset) = @_;
            my $dbh = CRP::Model::Schema->connect(sub {return $connector->dbh});
            return $resultset ? $dbh->resultset($resultset) : $dbh;
        }
    );

    # Router
    my $r = $self->routes;

    $r->get('/')->to('main#welcome');
    $r->any('/main/register_interest')->to('main#register_interest');
    $r->get('/page/*page')->to('main#page');

    my $tests=$r->under('/test')->to('test#authenticate');
    $tests->get('/')->to('test#welcome');
    $tests->get('/template/*template')->to('test#template');
}

sub _build_connector {
    my($config) = @_;

    my $dsn = 'dbi:' . $config->{driver}
    . ':dbname=' . $config->{dbname}
    . ';host='   . $config->{host}
    . ';port='   . $config->{port};

    return DBIx::Connector->new($dsn, $config->{username}, $config->{password});
}


1;
