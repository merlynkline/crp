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

