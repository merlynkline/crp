package CRP::Model::OLC::Page;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use CRP::Model::OLC::ComponentSet::ForPage;

use constant {
    _DB_FIELDS      => [qw(name notes description title)],
    _RESULTSET_NAME => 'OLCPage',
};

has '+_db_record' => (handles => _DB_FIELDS);

has component_set => (is => 'ro', lazy => 1, builder => '_build_component_set', init_arg => undef);

sub view_data {
    my $self = shift;

    my $data = $self->SUPER::view_data();
    $data->{components} = $self->component_set->view_data;

    return $data;
}

sub _build_component_set {
    my $self = shift;

    return CRP::Model::OLC::ComponentSet::ForPage->new(dbh => $self->dbh, page_id => $self->id);
}

__PACKAGE__->meta->make_immutable;

1;

