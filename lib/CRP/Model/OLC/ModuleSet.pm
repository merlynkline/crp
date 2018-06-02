package CRP::Model::OLC::ModuleSet;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObjectSet';

use List::Util 'sum';

use CRP::Model::OLC::Module;

has module_page_list => (is => 'ro', isa => 'ArrayRef', builder => '_build_module_page_list');

use constant {
    _RESULTSET_NAME => 'OLCModule',
    _MEMBER_CLASS   => 'CRP::Model::OLC::Module',
};

sub page_count {
    my $self = shift;

    return
        sum
        map { $_->page_set->count }
        @{$self->all};
}

sub _build_module_page_list {
    my $self = shift;

    my @module_page_list;
    foreach my $module (@{$self->all}) {
        my $module_id = $module->id;
        push @module_page_list,
            map { "$module_id:" . $_->id }
            @{$module->page_set->all};
    }

    return \@module_page_list;
}

__PACKAGE__->meta->make_immutable;

1;

