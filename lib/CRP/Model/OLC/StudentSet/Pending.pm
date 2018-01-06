package CRP::Model::OLC::StudentSet::Pending;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::StudentSet';

sub _build_ids {
    my $self = shift;

    return [
        map $_->id, $self->_resultset->search(
            {status  => 'PENDING'},
            {columns => 'id'}
        )
    ];
}

__PACKAGE__->meta->make_immutable;

1;

