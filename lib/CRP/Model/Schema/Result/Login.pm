package CRP::Model::Schema::Result::Login;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('login');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'login_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    email => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    create_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        default_value       => \'(now())',
        is_nullable         => 0,
    },
    last_login_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        is_nullable         => 1,
    },
    password_hash => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    otp_hash => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    otp_expiry_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        is_nullable         => 1,
    },
    is_administrator => {
        data_type           => 'boolean',
        is_nullable         => 1,
    },
    auto_login => {
        data_type           => 'boolean',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('login_email_key', ['email']);

1;

