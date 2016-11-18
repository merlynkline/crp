package CRP::Model::Schema::ResultSet::Professional;

use strict;
use warnings;

use base qw(DBIx::Class::ResultSet CRP::Model::Schema::date_utils);

use CRP::Util::WordNumber;

sub find_by_slug {
    my $self = shift;
    my($slug) = @_;

    my $id = $slug;
    $id = CRP::Util::WordNumber::decode_number($id) unless $id =~ /^\d+$/;
    return unless $id && length $id < 10;
    return $self->find({id => $id});
}

1;

