package CRP::Model::OLC::Component;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use Carp;

use constant {
    _DB_FIELDS      => [qw(olc_page_id name build_order data_version data)],
    _RESULTSET_NAME => 'OLCComponent',
    _TYPES          => {
        HEADING         => 1,
        PARAGRAPH       => 1,
        IMAGE           => 1,
        VIDEO           => 1,
        PDF             => 1,
        COURSE_IDX      => 1,
        MODULE_IDX      => 1,
        TEST            => 1,
    },
};

has '+_db_record' => (handles => _DB_FIELDS);

sub view_data {
    my $self = shift;

    my $data = $self->SUPER::view_data();
    $data->{type} = $self->type;

    return $data;
}

sub type {
    my $self = shift;

    if(@_) {
        my($new_type) = @_;
        $self->_check_type($new_type);
        $self->_db_record->type($new_type);
    }
    return $self->_db_record->type;
}

sub create_or_update {
    my $self = shift;

    $self->_check_type($self->type);;
    return $self->SUPER::create_or_update();
}

sub _check_type {
    my $self = shift;
    my($type) = @_;

    $type //= '';
    croak "Unrecognised component type '$type'" unless exists _TYPES->{$type};
    return;
}

__PACKAGE__->meta->make_immutable;

1;

