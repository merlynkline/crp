package CRP::Model::Schema::Result::OLCPageComponentLink;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('olc_page_component_link');
__PACKAGE__->add_columns(
    olc_page_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    olc_component_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    config => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    order => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key(qw(olc_page_id olc_component_id));
__PACKAGE__->belongs_to(page      => 'CRP::Model::Schema::Result::OLCPage',      {'foreign.id' => 'self.olc_page_id'});
__PACKAGE__->belongs_to(component => 'CRP::Model::Schema::Result::OLCComponent', {'foreign.id' => 'self.olc_component_id'});

1;

