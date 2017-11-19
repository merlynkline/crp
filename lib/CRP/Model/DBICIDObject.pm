package CRP::Model::DBICIDObject;
use Moose;
use namespace::autoclean;

use Carp;

use Data::GUID;
use DateTime;

has id          => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_id');
has guid        => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_guid');
has dbh         => (is => 'ro', required => 1);
has _db_record  => (is => 'ro', builder => '_build_db_record', lazy => 1);

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
    $self->_db_record->update_or_insert;
    $self->_set_id($self->_db_record->id);
}

sub touch {
    my $self = shift;

    $self->last_update_date(DateTime->now);
    $self->_db_record->update;
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
    if($self->guid) {
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

    $self->_db_record if $self->guid; # Force load to validate
}

sub _get_new_guid {
    return substr(Data::GUID->guid_base64, 0, -2);
}

__PACKAGE__->meta->make_immutable;

1;

