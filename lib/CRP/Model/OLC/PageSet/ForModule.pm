package CRP::Model::OLC::PageSet::ForModule;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::PageSet';

with 'CRP::Model::DBICIDObjectSet::ChildrenOfParent', {-alias => {add_child => 'add_page'}};

has module_id => (is => 'ro', required => 1);

use constant {
    _link_table         => 'OLCModulePageLink',
    _parent_id_column   => 'olc_module_id',
    _child_id_column    => 'olc_page_id',
    _parent_class       => 'CRP::Model::OLC::Module',
};

sub _parent_id { goto &module_id }

__PACKAGE__->meta->make_immutable;

1;

