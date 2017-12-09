package CRP::Model::OLC::UntypedComponent;
use Moose;
use namespace::autoclean;

use Mojo::JSON qw(decode_json encode_json);

extends 'CRP::Model::DBICIDObject';

use constant {
    _DB_FIELDS      => [qw(name build_order data_version data type olc_page_id last_update_date)],
    _RESULTSET_NAME => 'OLCComponent',
};

has '+_db_record' => (handles => _DB_FIELDS);

sub is_question {
    return ! ! shift->can('is_good_answer');
}

sub _json_encoder {
    my $orig = shift;
    my $self = shift;

    if(@_) {
        my ($data) = @_;
        $data = encode_json($data) if $data;
        return $self->$orig($data);
    }
    my $data = $self->$orig;
    $data = decode_json($data) if $data;
    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

