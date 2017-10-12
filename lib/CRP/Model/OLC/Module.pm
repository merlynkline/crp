package CRP::Model::OLC::Module;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use constant {
    _DB_FIELDS      => [qw(name description title)],
    _RESULTSET_NAME => 'OLCModule',
};

has '+_db_record' => (handles => _DB_FIELDS);

__PACKAGE__->meta->make_immutable;

1;

