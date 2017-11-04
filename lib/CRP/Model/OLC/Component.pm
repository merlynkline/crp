package CRP::Model::OLC::Component;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use Carp;

use constant {
    _DB_FIELDS      => [qw(olc_page_id name build_order data_version data)],
    _RESULTSET_NAME => 'OLCComponent',
    _TYPES          => {
        HEADING         => 1,
#        PARAGRAPH       => 1,
#        IMAGE           => 1,
#        VIDEO           => 1,
#        PDF             => 1,
#        COURSE_IDX      => 1,
#        MODULE_IDX      => 1,
#        TEST            => 1,
    },
};

enum ComponentType => [keys %{_TYPES()}];

has type => (is => 'ro', isa => 'ComponentType');

has '+_db_record' => (handles => _DB_FIELDS);

sub view_data {
    my $self = shift;

    my $data = $self->SUPER::view_data();
    $data->{type} = $self->type;

    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

