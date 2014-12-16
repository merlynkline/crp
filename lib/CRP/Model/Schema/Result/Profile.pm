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

__PACKAGE__->set_primary_key('instructor_id');
__PACKAGE__->add_unique_constraint('web_page_slug_key', ['web_page_slug']);



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
    $self->web_page_slug($self->_generate_slug($value)) if $column eq 'name';

    $self->SUPER::set_column($column, $value);
}

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(web_page_slug)) {
        $sqlt_table->add_index(name => "profile_${column}_idx", fields => [$column]);
    }
}

sub _generate_slug {
    my $self = shift;
    my($name) = @_;

    my $slug = lc $name;
    $slug =~ s{\s+}{-}g;
    $slug =~ s{[^a-z -]}{}g;
    $slug =~ s{^-+|-+$}{}g;
    $slug =~ s{--+}{-}g;
    my $dup_exists = 1;
    while($dup_exists) {
        my $dup_row = $self->result_source->resultset->find({web_page_slug => $slug});
        $dup_exists = $dup_row && $dup_row->instructor_id != $self->instructor_id;
        $slug = _de_dup_slug($slug) if $dup_exists;
    }

    return $slug;
}

sub _de_dup_slug {
    my($str) = @_;

    $str = $1 if $str =~ m{^(.+)-\d+$};
    $str .= '-' . int rand 10000;
    return $str;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub is_complete {
    my $self = shift;

    return $self->name && ($self->telephone || $self->mobile) && $self->postcode && $self->blurb;
}

1;

