package CRP::Model::OLC::PageSet;
use Moose;
use namespace::autoclean;

use CRP::Model::OLC::Page;

extends 'CRP::Model::DBICIDObjectSet';

use constant {
    _RESULTSET_NAME => 'OLCPage',
    _MEMBER_CLASS   => 'CRP::Model::OLC::Page',
};

__PACKAGE__->meta->make_immutable;

1;

