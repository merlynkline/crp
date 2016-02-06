package CRP::Model::Schema::Result::Qualification;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Carp;

use DateTime;

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('qualification');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'qualification_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    qualification => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    abbreviation => {
        data_type           => 'text',
        is_nullable         => 0,
    },
);

__PACKAGE__->set_primary_key('id');

1;

