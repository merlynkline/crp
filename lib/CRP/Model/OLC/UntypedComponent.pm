package CRP::Model::OLC::UntypedComponent;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use constant {
    _DB_FIELDS      => [qw(name build_order data_version data type olc_page_id last_update_date)],
    _RESULTSET_NAME => 'OLCComponent',
};

has '+_db_record' => (handles => _DB_FIELDS);

__PACKAGE__->meta->make_immutable;

1;

