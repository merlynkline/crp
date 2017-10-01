package CRP::Model::OLCCourse;
use Moose;

use Carp;

use constant _DB_FIELDS => qw(name description title);

has id          => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_id');
has dbh         => (is => 'ro', required => 1);
has _db_record  => (is => 'ro', isa => 'CRP::Model::Schema::Result::OLCCourse', builder => '_build_db_record', lazy => 1, handles => [_DB_FIELDS]);

sub get_data_for_template {
    my $self = shift;

    my $template_data = {};
    foreach my $field ('id', _DB_FIELDS) {
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

    my $resultset = $self->dbh->resultset('OLCCourse');
    my $res;
    if($self->id) {
        $res = $resultset->find($self->id);
        croak "Couldn't load OLC course ID '" . $self->id . "'" unless $res;
    }
    else {
        $res = $resultset->new_result({});
    }
    return $res;
}

1;

