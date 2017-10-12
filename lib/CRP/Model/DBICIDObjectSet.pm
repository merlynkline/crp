package CRP::Model::DBICIDObjectSet;
use Moose::Role;

requires qw(
    _RESULTSET_NAME
    _MEMBER_CLASS
    _where_clause
);

has dbh  => (is => 'ro', required => 1);
has _ids => (is => 'ro', isa => 'ArrayRef', builder => '_build_ids', lazy => 1);

sub all {
    my $self = shift;

    return [ map $self->_MEMBER_CLASS->new(dbh => $self->dbh, id => $_), @{$self->_ids} ];
}

sub get_data_for_template {
    my $self = shift;

    return [ map $_->get_data_for_template, @{$self->all} ];
}

sub _build_ids {
    my $self = shift;

    return [
        map $_->id, $self->dbh->resultset($self->_RESULTSET_NAME)->search($self->_where_clause, {columns => 'id'})
    ];
}

1;

