package CRP::Model::OLC::Component;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Carp;

use CRP::Model::OLC::UntypedComponent;

use constant {
    _DB_FIELDS      => [qw(name build_order data_version data type olc_page_id)],
    _TYPES          => {
        HEADING         => 1,
        PARAGRAPH       => 1,
        IMAGE           => 1,
        VIDEO           => 1,
        PDF             => 1,
        COURSE_IDX      => 1,
        MODULE_IDX      => 1,
        TEST            => 1,
    },
};

enum ComponentType => [keys %{_TYPES()}];

has _type        => (is => 'ro', isa => 'Maybe[ComponentType]', init_arg => 'type');
has _olc_page_id => (is => 'ro', isa => 'Maybe[Int]',           init_arg => 'olc_page_id');
has id           => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_id');
has dbh          => (is => 'ro', required => 1);

has _component => (is => 'ro', lazy => 1, builder => '_build_component', init_arg => undef, handles => [qw(
    name build_order data_version data olc_page_id type
)]);

sub create_or_update {
    my $self = shift;

    $self->_component->create_or_update;
    $self->_set_id($self->_component->id);
}

sub view_data {
    my $self = shift;

    my $data = $self->_component->view_data;
    my $type = $self->type // '';
    if($type eq 'HEADING') {
        $data->{heading_text} = $self->_component->data;
    }
    elsif($type eq 'PARAGRAPH') {
        $data->{paragraph_text} = $self->_component->data;
    }

    return $data;
}

sub _build_component {
    my $self = shift;

    my $component = CRP::Model::OLC::UntypedComponent->new({dbh => $self->dbh, id => $self->id});
    unless($self->id) {
        $component->olc_page_id($self->_olc_page_id);
        $component->type($self->_type);
    }
    return $component;
}

sub BUILD {
    my $self = shift;

    return if $self->id;
    return if $self->olc_page_id && $self->type;
    croak __PACKAGE__ . ' requires an id or both an olc_page_id and a type';
}

__PACKAGE__->meta->make_immutable;

1;

