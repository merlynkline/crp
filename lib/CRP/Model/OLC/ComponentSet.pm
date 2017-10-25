package CRP::Model::OLC::ComponentSet;
use Moose;
use namespace::autoclean;

use CRP::Model::OLC::Component;

extends 'CRP::Model::DBICIDObjectSet';

use constant {
    _RESULTSET_NAME => 'OLCComponent',
    _MEMBER_CLASS   => 'CRP::Model::OLC::Component',
};

__PACKAGE__->meta->make_immutable;

1;

