use utf8;
package CRP::Model::Schema::Result::Enquiry;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('InflateColumn::DateTime');
__PACKAGE__->table('enquiry');

__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => 'enquiry_id_seq',
    },
    'email' => { data_type => 'varchar', is_nullable => 0, size => 255 },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('enquiry_email_key', ['email']);

1;
