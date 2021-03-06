package CRP::Model::DBICIDObject;
use Moose;
use namespace::autoclean;

use Carp;

use Mojo::JSON qw(decode_json encode_json);

use Try::Tiny;
use Data::GUID;
use DateTime;

has id               => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_id');
has guid             => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_guid');
has _serialised_data => (is => 'ro', isa => 'Str',        init_arg => 'serialised_data');
has dbh              => (is => 'ro', required => 1);
has _db_record       => (is => 'ro', builder => '_build_db_record', lazy => 1);

sub serialised {
    my $self = shift;

    my $data = {};
    foreach my $field ('guid', @{$self->_DB_FIELDS}) {
        $data->{$field} = $self->$field;
    }

    $self->_prepare_data_for_serialisation($data);

    return encode_json($data);
}

sub _prepare_data_for_serialisation {
    my $self = shift;
    my($data) = @_;

    return $data;
}

sub deserialise {
    my $self = shift;
    my($serialised_data) = @_;

    my $data = decode_json($serialised_data);

    $self->_prepare_deserialised_data_for_db($data);

    foreach my $field (@{$self->_DB_FIELDS}) {
        $self->$field($data->{$field});
    }
    $self->_set_guid($data->{guid});

    return;
}

sub _prepare_deserialised_data_for_db {
    my $self = shift;
    my($data) = @_;

    return $data;
}

sub view_data {
    my $self = shift;

    my $template_data = {};
    foreach my $field ('id', @{$self->_DB_FIELDS}) {
        $template_data->{$field} = $self->$field;
    }

    return $template_data;
}

sub state_data {
    my $self = shift;

    return {
        guid                => $self->guid,
        last_update_date    => $self->last_update_date,
    };
}

sub create_or_update {
    my $self = shift;
    my($as_at_date) = @_;

    $self->_set_guid($self->_get_new_guid) unless $self->guid;
    $self->last_update_date($as_at_date // DateTime->now);
    $self->_db_record->guid($self->guid);
    $self->_db_record->update_or_insert;
    $self->_set_id($self->_db_record->id);
}

sub touch {
    my $self = shift;

    $self->last_update_date(DateTime->now);
    $self->_db_record->update;
}

sub exists {
    my $self = shift;

    my $exists = '';
    try {
        $exists = $self->id && $self->_db_record;
    };

    return ! ! $exists;
}

sub _build_db_record {
    my $self = shift;

    my $resultset = $self->dbh->resultset($self->_RESULTSET_NAME);
    my $res;
    if($self->id) {
        $res = $resultset->find($self->id);
        croak "Couldn't load " . $self->_RESULTSET_NAME ." ID '" . $self->id . "'" unless $res;
        $self->_set_guid($res->guid);
    }
    elsif($self->guid) {
        $res = $resultset->find({guid => $self->guid});
        croak "Couldn't load " . $self->_RESULTSET_NAME ." GUID '" . $self->guid . "'" unless $res;
        $self->_set_id($res->id);
    }
    else {
        $res = $resultset->new_result({});
    }
    return $res;
}

sub BUILD {
    my $self = shift;

    $self->_db_record if $self->guid || $self->id; # Force load to validate
    $self->deserialise($self->_serialised_data) if $self->_serialised_data;
}

sub _get_new_guid {
    return substr(Data::GUID->guid_base64, 0, -2);
}

__PACKAGE__->meta->make_immutable;

1;

