package CRP::Model::Schema::Result::Profile;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use CRP::Util::Types;

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('profile');
__PACKAGE__->add_columns(
    instructor_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    name => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    address => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    postcode => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    telephone => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    mobile => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    photo => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    blurb => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    web_page_slug => {
        data_type           => 'text',
        is_nullable         => 1,
    },
);

my %TYPE = (
    name        => {MinLen => 1, MaxLen => 150},
    address     => {MaxLen => 300},
    postcode    => {MinLen => 1, MaxLen => 10},
    blurb       => {MaxLen => 2000},
);

sub set_column {
    my $self = shift;
    my($column, $value) = @_;

    CRP::Util::Types::type_check($TYPE{$column}, $value) if exists $TYPE{$column};

    $self->SUPER::set_column($column, $value);
}

__PACKAGE__->set_primary_key('instructor_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(web_page_slug)) {
        $sqlt_table->add_index(name => "profile_${column}_idx", fields => [$column]);
    }
}



sub is_complete {
    my $self = shift;

    return $self->name && ($self->telephone || $self->mobile) && $self->postcode && $self->blurb;
}

1;

