package CRP::Model::Schema::Result::OLCComponent;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('olc_component');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'olc_component_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    olc_page_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    build_order => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
    name => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    type => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    data_version => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    data => {
        data_type           => 'text',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(page => 'CRP::Model::Schema::Result::OLCPage',      {'foreign.id' => 'self.olc_page_id'});

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(olc_page_id)) {
        $sqlt_table->add_index(name => "olc_component_${column}_idx", fields => [$column]);
    }
}


1;

