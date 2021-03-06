package CRP::Model::Schema::Result::OLCPage;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('olc_page');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'olc_page_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    name => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    notes => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    description => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    title => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    guid => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    last_update_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('module_links' => 'CRP::Model::Schema::Result::OLCModulePageLink', {'foreign.olc_page_id' => 'self.id'});
__PACKAGE__->has_many('components'   => 'CRP::Model::Schema::Result::OLCComponent',      {'foreign.olc_page_id' => 'self.id'});

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(guid)) {
        $sqlt_table->add_index(name => "olc_page_${column}_idx", fields => [$column]);
    }
}

1;

