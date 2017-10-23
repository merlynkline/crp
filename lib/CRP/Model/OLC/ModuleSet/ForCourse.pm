package CRP::Model::OLC::ModuleSet::ForCourse;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::ModuleSet';

has course_id => (is => 'ro', required => 1);

sub _build_ids {
    my $self = shift;

    return [
        map $_->olc_module_id, $self->_resultset->search(
            {olc_course_id => $self->course_id},
            {
                columns     => 'olc_module_id',
                order_by    => 'order',
            }
        )
    ];
}

sub add_module {
    my $self = shift;
    my($id) = @_;

warn "a:$id";
    return if $self->includes_id($id);
warn "b:",$self->course_id;
    $self->_resultset->create({
        olc_module_id => $id,
        olc_course_id => $self->course_id,
    });
warn "c:";
    push @{$self->_ids}, $id;
}

sub _resultset {
    my $self = shift;

    return $self->dbh->resultset('OLCCourseModuleLink');
}

__PACKAGE__->meta->make_immutable;

1;

