package CRP::Model::OLC::PageSet::ForModule;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::PageSet';

has module_id => (is => 'ro', required => 1);

sub _build_ids {
    my $self = shift;

    return [
        map $_->id, $self->dbh->resultset('OLCModulePageLink')->search(
            {olc_module_id => $self->module_id},
            {
                columns     => {id => 'olc_page_id'},
                order_by    => 'order',
            }
        )
    ];
}

__PACKAGE__->meta->make_immutable;

1;

