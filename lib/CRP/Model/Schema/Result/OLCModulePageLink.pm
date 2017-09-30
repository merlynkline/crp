package CRP::Model::Schema::Result::OLCModulePageLink;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('olc_module_page_link');
__PACKAGE__->add_columns(
    olc_module_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    olc_page_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    order => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key(qw(olc_module_id olc_page_id));
__PACKAGE__->belongs_to(module => 'CRP::Model::Schema::Result::OLCModule', {'foreign.id' => 'self.olc_module_id'});
__PACKAGE__->belongs_to(page   => 'CRP::Model::Schema::Result::OLCPage',   {'foreign.id' => 'self.olc_page_id'});

1;

