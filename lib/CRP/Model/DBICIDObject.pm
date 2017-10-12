package CRP::Model::DBICIDObject;
use Moose;
use namespace::autoclean;

use Carp;

has id          => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_id');
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

sub create_or_update {
    my $self = shift;

    $self->_db_record->update_or_insert;
    $self->_set_id($self->_db_record->id);
}

sub _build_db_record {
    my $self = shift;

    my $resultset = $self->dbh->resultset($self->_RESULTSET_NAME);
    my $res;
    if($self->id) {
        $res = $resultset->find($self->id);
        croak "Couldn't load " . $self->_RESULTSET_NAME ." ID '" . $self->id . "'" unless $res;
    }
    else {
        $res = $resultset->new_result({});
    }
    return $res;
}

__PACKAGE__->meta->make_immutable;

1;

