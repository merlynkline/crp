use utf8;
package CRP::Model::Schema::Result::Enquiry;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('enquiry');
__PACKAGE__->add_columns(
    'id' => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'enquiry_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    name => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    'email' => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    create_date => {
        data_type           => 'timestamp',
        default_value       => \'SYSDATE',
        is_nullable         => 0,
    },
    suspend_date => {
        data_type           => 'timestamp',
        is_nullable         => 1,
    },
    location => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    latitude => {
        data_type           => 'real',
        is_nullable         => 1,
    },
    longitude => {
        data_type           => 'real',
        is_nullable         => 1,
    },
    notify_new_courses => {
        data_type           => 'boolean',
        is_nullable         => 1,
    },
    notify_tutors => {
        data_type           => 'boolean',
        is_nullable         => 1,
    },
    send_newsletter => {
        data_type           => 'boolean',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('enquiry_email_key', ['email']);

1;

