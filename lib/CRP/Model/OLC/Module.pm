package CRP::Model::OLC::Module;
use Moose;
use namespace::autoclean;

use constant {
    _DB_FIELDS      => [qw(name description title)],
    _RESULTSET_NAME => 'OLCModule',
};

with 'CRP::Model::DBICIDObject';

has '+_db_record' => (handles => _DB_FIELDS);

__PACKAGE__->meta->make_immutable;

1;

