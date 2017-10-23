package CRP::Model::DBICIDObjectSet;
use Moose;
use namespace::autoclean;

has dbh  => (is => 'ro', required => 1);
has _ids => (is => 'ro', isa => 'ArrayRef', builder => '_build_ids', lazy => 1);

sub all {
    my $self = shift;

    return [ map $self->_MEMBER_CLASS->new(dbh => $self->dbh, id => $_), @{$self->_ids} ];
}

sub view_data {
    my $self = shift;

    return [ map $_->view_data, @{$self->all} ];
}

sub includes_id {
    my $self = shift;
    my($id) = @_;

    return defined $self->index_of($id);
}

sub index_of {
    my $self = shift;
    my($id) = @_;

    my $index = 0;
    while($index < $self->count) {
        return $index if $self->_ids->[$index] == $id;
        $index++;
    }
    return undef;
}

sub count {
    my $self = shift;

    return scalar @{$self->_ids};
}

sub _build_ids {
    my $self = shift;

    return [
        map $_->id, $self->dbh->resultset($self->_RESULTSET_NAME)->search($self->_where_clause, {columns => 'id'})
    ];
}

sub _where_clause {
    return {};
}

__PACKAGE__->meta->make_immutable;

1;

