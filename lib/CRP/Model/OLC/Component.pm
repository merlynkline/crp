package CRP::Model::OLC::Component;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use constant {
    _DB_FIELDS      => [qw(name notes title type data_version data)],
    _RESULTSET_NAME => 'OLCComponent',
};

has '+_db_record' => (handles => _DB_FIELDS);

sub view_data {
    my $self = shift;

    my $data = $self->SUPER::view_data();

    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

