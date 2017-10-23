package CRP::Model::OLC::CourseSet;
use Moose;
use namespace::autoclean;

use CRP::Model::OLC::Course;

extends 'CRP::Model::DBICIDObjectSet';

use constant {
    _RESULTSET_NAME => 'OLCCourse',
    _MEMBER_CLASS   => 'CRP::Model::OLC::Course',
};

__PACKAGE__->meta->make_immutable;

1;

