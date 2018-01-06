package CRP::Model::OLC::Page;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use CRP::Model::OLC::ComponentSet::ForPage;

use constant {
    _DB_FIELDS      => [qw(name notes description title last_update_date)],
    _RESULTSET_NAME => 'OLCPage',
};

has '+_db_record' => (handles => _DB_FIELDS);

has component_set => (is => 'ro', lazy => 1, builder => '_build_component_set', init_arg => undef);

override view_data => sub {
    my $self = shift;
    my($module_context, $course_context) = @_;

    my $data = super();
    $data->{components} = $self->component_set->view_data($module_context, $course_context) if $module_context && $course_context;

    return $data;
};

override state_data => sub {
    my $self = shift;

    my $data = super();
    $data->{components} = $self->component_set->state_data;

    return $data;
};

sub view_data_without_components {
    my $self = shift;

    return $self->SUPER::view_data;
}

sub _build_component_set {
    my $self = shift;

    return CRP::Model::OLC::ComponentSet::ForPage->new(dbh => $self->dbh, page_id => $self->id);
}

__PACKAGE__->meta->make_immutable;

1;

