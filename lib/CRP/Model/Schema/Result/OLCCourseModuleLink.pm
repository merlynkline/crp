package CRP::Model::Schema::Result::OLCCourseModuleLink;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('olc_course_module_link');
__PACKAGE__->add_columns(
    olc_course_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    olc_module_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    order => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key(qw(olc_course_id olc_module_id));
__PACKAGE__->belongs_to(course => 'CRP::Model::Schema::Result::OLCCourse', {'foreign.id' => 'self.olc_course_id'});
__PACKAGE__->belongs_to(module => 'CRP::Model::Schema::Result::OLCModule', {'foreign.id' => 'self.olc_module_id'});

1;

