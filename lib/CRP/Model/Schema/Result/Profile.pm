package CRP::Model::Schema::Result::Profile;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('profile');
__PACKAGE__->add_columns(
    instructor_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    name => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    address => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    postcode => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    telephone => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    mobile => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    photo => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    blurb => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    web_page_slug => {
        data_type           => 'text',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('instructor_id');

1;

