package CRP::Model::Schema::Result::PremiumAuthorisation;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('premium_authorisation');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'instructor_qualification_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    create_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        default_value       => \'(now())',
        is_nullable         => 0,
    },
    directory => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    email => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    name => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    is_disabled => {
        data_type           => 'boolean',
        is_nullable         => 0,
    },
);

__PACKAGE__->set_primary_key('id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(email)) {
        $sqlt_table->add_index(name => "premium_authorisation_${column}_idx", fields => [$column]);
    }
}

__PACKAGE__->has_many('cookies' => 'CRP::Model::Schema::Result::PremiumCookieLog', 'auth_id');

1;

