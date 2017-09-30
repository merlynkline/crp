package CRP::Model::Schema::Result::OLCComponent;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('olc_Component');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'olc_component_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    name => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    description => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    title => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    type => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    data_version => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    data => {
        data_type           => 'text',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('page_links' => 'CRP::Model::Schema::Result::OLCPageComponentLink', {'foreign.olc_component_id' => 'self.id'});

1;

