package CRP::Model::OLC::CourseSet;
use Moose;
use namespace::autoclean;

use constant {
    _RESULTSET_NAME => 'OLCCourse',
    _MEMBER_CLASS   => 'CRP::Model::OLC::Course',
};

with 'CRP::Model::DBICIDObjectSet';

sub _where_clause {
    return {};
}

__PACKAGE__->meta->make_immutable;

1;

