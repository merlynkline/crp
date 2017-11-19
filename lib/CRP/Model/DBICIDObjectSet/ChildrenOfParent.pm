package CRP::Model::DBICIDObjectSet::ChildrenOfParent;
use Moose::Role;
use namespace::autoclean;

requires qw(
    _link_table
    _parent_id_column
    _child_id_column
    _parent_id
    _parent_class
);

sub _build_ids {
    my $self = shift;

    my $parent_id_column = $self->_parent_id_column;
    my $child_id_column = $self->_child_id_column;
    return [
        map $_->$child_id_column, $self->_resultset->search(
            {$parent_id_column => $self->_parent_id},
            {
                columns     => $child_id_column,
                order_by    => 'order',
            }
        )
    ];
}

sub add_child {
    my $self = shift;
    my($id) = @_;

    return if $self->includes_id($id);
    $self->_resultset->create({
        $self->_child_id_column   => $id,
        $self->_parent_id_column  => $self->_parent_id,
        order                     => $self->max_order + 1,
    });
    $self->_touch_parent;
    push @{$self->_ids}, $id;
}

sub max_order {
    my $self = shift;

    return $self->_resultset->search(
            {$self->_parent_id_column => $self->_parent_id}
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

    my $record1 = $self->_resultset->find({$self->_parent_id_column => $self->_parent_id, $self->_child_id_column => $id1});
    my $order1  = $record1->order;
    my $record2 = $self->_resultset->find({$self->_parent_id_column => $self->_parent_id, $self->_child_id_column => $id2});
    $record1->order($record2->order);
    $record2->order($order1);
    $record1->update;
    $record2->update;
    $self->_touch_parent;

    ($self->_ids->[$index1], $self->_ids->[$index2]) = ($self->_ids->[$index2], $self->_ids->[$index1]);
}

sub delete {
    my $self = shift;
    my($id) = @_;

    my $index = $self->index_of($id);
    return unless defined $index;
    $self->_resultset->find({$self->_parent_id_column => $self->_parent_id, $self->_child_id_column => $id})->delete;
    $self->_touch_parent;

    splice @{$self->_ids}, $index, 1;
}

sub _resultset {
    my $self = shift;

    return $self->dbh->resultset($self->_link_table);
}

sub _touch_parent {
    my $self = shift;

    $self->_parent_class->new({dbh => $self->dbh, id => $self->_parent_id})->touch;
}


1;

