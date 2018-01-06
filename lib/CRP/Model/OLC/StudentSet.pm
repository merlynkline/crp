package CRP::Model::OLC::StudentSet;
use Moose;
use namespace::autoclean;

use CRP::Model::OLC::Student;

extends 'CRP::Model::DBICIDObjectSet';

use constant {
    _RESULTSET_NAME => 'OLCStudent',
    _MEMBER_CLASS   => 'CRP::Model::OLC::Student',
};

__PACKAGE__->meta->make_immutable;

1;

