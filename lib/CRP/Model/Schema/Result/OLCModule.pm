package CRP::Model::Schema::Result::OLCModule;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('olc_module');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'olc_module_id_seq',
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
    landing_olc_page_id => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(landing_page => 'CRP::Model::Schema::Result::OLCPage', {'foreign.id' => 'self.landing_olc_page_id'});
__PACKAGE__->has_many('course_links' => 'CRP::Model::Schema::Result::OLCCourseModuleLink', {'foreign.olc_module_id' => 'self.id'});
__PACKAGE__->has_many('page_links'   => 'CRP::Model::Schema::Result::OLCModulePageLink',   {'foreign.olc_module_id' => 'self.id'});

1;

