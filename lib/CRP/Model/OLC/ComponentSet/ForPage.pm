package CRP::Model::OLC::ComponentSet::ForPage;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::ComponentSet';

has page_id => (is => 'ro', required => 1);

sub _build_ids {
    my $self = shift;

    return [
        map $_->olc_component_id, $self->_resultset->search(
            {olc_page_id => $self->page_id},
            {
                columns     => 'olc_component_id',
                order_by    => 'order',
            }
        )
    ];
}

sub add_component {
    my $self = shift;
    my($id) = @_;

    return if $self->includes_id($id);
    $self->_resultset->create({
        olc_component_id => $id,
        olc_page_id      => $self->page_id,
        order            => $self->max_order + 1,
    });
    push @{$self->_ids}, $id;
}

sub max_order {
    my $self = shift;

    return $self->_resultset->search(
        {olc_page_id => $self->page_id}
    )->get_column('order')->max || 0;
}

sub move_up {
    my $self = shift;
    my($id) = @_;

    return unless $self->count > 1;
    my $index = $self->index_of($id);
    return unless $index > 0;

    my $previous_id = $self->_ids->[$index - 1];
    $self->_swap_ids($id, $previous_id);
}

sub move_down {
    my $self = shift;
    my($id) = @_;

    return unless $self->count > 1;
    my $index = $self->index_of($id);
    return unless $index < $self->count - 1;

    my $next_id = $self->_ids->[$index + 1];
    $self->_swap_ids($id, $next_id);
}

sub _swap_ids {
    my $self = shift;
    my($id1, $id2) = @_;

    my $index1 = $self->index_of($id1);
    my $index2 = $self->index_of($id2);
    return unless defined $index1 && defined $index2;

    my $record1 = $self->_resultset->find({olc_page_id => $self->page_id, olc_component_id => $id1});
    my $order1  = $record1->order;
    my $record2 = $self->_resultset->find({olc_page_id => $self->page_id, olc_component_id => $id2});
    $record1->order($record2->order);
    $record2->order($order1);
    $record1->update;
    $record2->update;

    ($self->_ids->[$index1], $self->_ids->[$index2]) = ($self->_ids->[$index2], $self->_ids->[$index1]);
}

sub delete {
    my $self = shift;
    my($id) = @_;

    my $index = $self->index_of($id);
    return unless $index;
    $self->_resultset->find({olc_page_id => $self->page_id, olc_component_id => $id})->delete;
    splice @{$self->_ids}, $index, 1;
}

sub _resultset {
    my $self = shift;

    return $self->dbh->resultset('OLCPageComponentLink');
}


__PACKAGE__->meta->make_immutable;

1;

