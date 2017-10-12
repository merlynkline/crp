package CRP::Model::OLC::ModuleSet::ForCourse;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::ModuleSet';

has course_id => (is => 'ro', required => 1);

sub _build_ids {
    my $self = shift;

    return [
        map $_->id, $self->dbh->resultset('OLCCourseModuleLink')->search(
            {olc_course_id => $self->course_id},
            {
                columns     => {id => 'olc_module_id'},
                order_by    => 'order',
            }
        )
    ];
}

__PACKAGE__->meta->make_immutable;

1;

