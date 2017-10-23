package CRP::Model::OLC::ModuleSet;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObjectSet';

use CRP::Model::OLC::Module;

use constant {
    _RESULTSET_NAME => 'OLCModule',
    _MEMBER_CLASS   => 'CRP::Model::OLC::Module',
};

__PACKAGE__->meta->make_immutable;

1;

