package CRP::Model::Schema::Result::Session;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('session');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'session_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    instructor_id => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
    data => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    last_access_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        default_value       => \'(now())',
        is_nullable         => 0,
    },
);

__PACKAGE__->set_primary_key('id');


1;

