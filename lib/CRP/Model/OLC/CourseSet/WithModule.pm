package CRP::Model::OLC::CourseSet::WithModule;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::CourseSet';

has module_id => (is => 'ro', required => 1);

sub _build_ids {
    my $self = shift;

    return [
        map $_->olc_course_id, $self->_resultset->search(
            {olc_module_id => $self->module_id},
            {columns       => 'olc_course_id'}
        )
    ];
}

sub _resultset {
    my $self = shift;

    return $self->dbh->resultset('OLCCourseModuleLink');
}

__PACKAGE__->meta->make_immutable;

1;

