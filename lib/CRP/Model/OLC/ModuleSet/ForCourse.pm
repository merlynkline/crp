package CRP::Model::OLC::ModuleSet::ForCourse;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::ModuleSet';

with 'CRP::Model::DBICIDObjectSet::ChildrenOfParent', {-alias => {
    add_child          => 'add_module',
    add_child_silently => 'add_module_silently',
}};

has course_id => (is => 'ro', required => 1);

use constant {
    _link_table         => 'OLCCourseModuleLink',
    _parent_id_column   => 'olc_course_id',
    _child_id_column    => 'olc_module_id',
    _parent_class       => 'CRP::Model::OLC::Course',
};

sub _parent_id { goto &course_id }

__PACKAGE__->meta->make_immutable;

1;

