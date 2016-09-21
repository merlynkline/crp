package CRP::Model::Schema;

use strict;
use warnings;

our $VERSION = 28;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

sub build_connector {
    my($config) = @_;

    my $dsn = build_dsn($config);
    return DBIx::Connector->new($dsn, $config->{username}, $config->{password}, {pg_enable_utf8 => 1});
}

sub build_dsn {
    my($config) = @_;

    my $dsn = 'dbi:' . $config->{driver} . ':dbname=' . $config->{dbname};
    $dsn .= ';host=' . $config->{host} if $config->{host};
    $dsn .= ';port=' . $config->{port} if $config->{port};

    return $dsn;
}

1;

