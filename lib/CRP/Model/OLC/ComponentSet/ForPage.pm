package CRP::Model::OLC::ComponentSet::ForPage;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::ComponentSet';

has page_id => (is => 'ro', required => 1);

sub _where_clause {
    my $self = shift;

    return { olc_page_id => $self->page_id };
}

__PACKAGE__->meta->make_immutable;

1;

