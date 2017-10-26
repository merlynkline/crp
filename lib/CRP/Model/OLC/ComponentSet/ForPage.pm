package CRP::Model::OLC::ComponentSet::ForPage;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::ComponentSet';

with 'CRP::Model::DBICIDObjectSet::ChildrenOfParent', {-alias => {add_child => 'add_component'}};

has page_id => (is => 'ro', required => 1);

use constant {
    _link_table         => 'OLCPageComponentLink',
    _parent_id_column   => 'olc_page_id',
    _child_id_column    => 'olc_component_id',
};

sub _parent_id { goto &page_id }

__PACKAGE__->meta->make_immutable;

1;

