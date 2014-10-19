package CRP::Command::migrate;
use Mojo::Base 'Mojolicious::Command';
use CRP::Model::Schema;
use DBIx::Class::Migration;

use Getopt::Long qw(GetOptions :config no_auto_abbrev no_ignore_case);

has description => "Wrapper for dbic-migration.\n";
has usage       => <<"EOF";
This is a wrapper for dbic-migration, q.v.
The --dsn, --username and --password options are set from
config and the DBIC_MIGRATION_SCHEMA_CLASS and
DBIC_MIGRATION_TARGET_DIR environment variables are
set for you. Pass the --init parameter to intialise
the database.
EOF

sub run {
    my $self = shift;

    # Options
    local @ARGV = @_;

    my $config = $self->app->plugin('Config')->{database};
    my $init = 0;
    GetOptions('init' => \$init);

    $ENV{DBIC_MIGRATION_SCHEMA_CLASS} = 'CRP::Model::Schema';
    $ENV{DBIC_MIGRATION_TARGET_DIR}   = 'share/deploy';

    my $dsn = CRP::Model::Schema::build_dsn($config);

    if($init) {
        my $schema = CRP::Model::Schema->connect(
            $dsn,
            $config->{username},
            $config->{password}
        );
        $schema->deploy;
    }
    else {
        unshift @ARGV, (
            '--dsn', $dsn,
            '--username', $config->{username},
            '--password', $config->{password},
        );
        (require DBIx::Class::Migration::Script)->run_with_options;
    }
}

1;


