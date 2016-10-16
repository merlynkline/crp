package CRP::Model::Schema::Result::PremiumCookieLog;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('premium_cookie_log');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'instructor_qualification_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    timestamp => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        default_value       => \'(now())',
        is_nullable         => 0,
    },
    auth_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    remote_id => {
        data_type           => 'text',
        is_nullable         => 0,
    },
);

__PACKAGE__->belongs_to('instructor' => 'CRP::Model::Schema::Result::PremiumAuthorisation', 'auth_id');

__PACKAGE__->set_primary_key('id');

1;

