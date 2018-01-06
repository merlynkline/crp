package CRP::Model::OLC::ComponentSet::AssignmentsForPage;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::OLC::ComponentSet';

use CRP::Model::OLC::Page;
use CRP::Model::OLC::Component;

has page_id => (is => 'ro', required => 1);

sub _build_ids {
    my $self = shift;

    return [
        map $_->id, $self->_resultset->search(
            {
                olc_page_id => $self->page_id,
                type => 'QTUTORMARKED'
            },
            {
                columns     => 'id',
                order_by    => 'build_order',
            }
        )
    ];
}


__PACKAGE__->meta->make_immutable;

1;

