package CRP::Model::OLC::Course;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use CRP::Model::OLC::ModuleSet::ForCourse;

use constant {
    _DB_FIELDS      => [qw(name description title)],
    _RESULTSET_NAME => 'OLCCourse',
};

has '+_db_record' => (handles => _DB_FIELDS);

has module_set    => (is => 'ro', lazy => 1, builder => '_build_module_set', init_arg => undef);

sub view_data {
    my $self = shift;

    my $data = $self->SUPER::view_data();
    $data->{modules} = $self->module_set->view_data;

    return $data;
}

sub _build_module_set {
    my $self = shift;

    return CRP::Model::OLC::ModuleSet::ForCourse->new(dbh => $self->dbh, course_id => $self->id);
}

__PACKAGE__->meta->make_immutable;

1;

