package CRP::Model::OLC::Module;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use CRP::Model::OLC::PageSet::ForModule;

use constant {
    _DB_FIELDS      => [qw(name notes description title guid last_update_date)],
    _RESULTSET_NAME => 'OLCModule',
};

has '+_db_record' => (handles => _DB_FIELDS);

has page_set    => (is => 'ro', lazy => 1, builder => '_build_page_set', init_arg => undef);

override view_data => sub {
    my $self = shift;

    my $data = super;
    $data->{pages} = $self->page_set->view_data_without_components;

    return $data;
};

override state_data => sub {
    my $self = shift;

    my $data = super();
    $data->{pages} = $self->page_set->state_data;

    return $data;
};

sub _build_page_set {
    my $self = shift;

    return CRP::Model::OLC::PageSet::ForModule->new(dbh => $self->dbh, module_id => $self->id);
}

__PACKAGE__->meta->make_immutable;

1;

