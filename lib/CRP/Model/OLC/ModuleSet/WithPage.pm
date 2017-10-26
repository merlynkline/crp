package CRP::Model::OLC::ModuleSet::WithPage;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::ModuleSet';

has page_id => (is => 'ro', required => 1);

sub _build_ids {
    my $self = shift;

    return [
        map $_->olc_module_id, $self->_resultset->search(
            {olc_page_id => $self->page_id},
            {columns       => 'olc_module_id'}
        )
    ];
}

sub _resultset {
    my $self = shift;

    return $self->dbh->resultset('OLCModulePageLink');
}

__PACKAGE__->meta->make_immutable;

1;

