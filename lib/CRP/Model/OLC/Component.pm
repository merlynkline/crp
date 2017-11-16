package CRP::Model::OLC::Component;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Carp;

use CRP::Model::OLC::UntypedComponent;
use CRP::Model::OLC::Course;
use CRP::Model::OLC::Module;
use CRP::Model::OLC::Component::CourseIndex;
use CRP::Model::OLC::Component::Heading;
use CRP::Model::OLC::Component::Image;
use CRP::Model::OLC::Component::Markdown;
use CRP::Model::OLC::Component::ModuleIndex;
use CRP::Model::OLC::Component::PDF;
use CRP::Model::OLC::Component::Paragraph;
use CRP::Model::OLC::Component::Test;
use CRP::Model::OLC::Component::Video;

use constant {
    _DB_FIELDS      => [qw(name build_order data_version data type olc_page_id)],
    _TYPES          => {
        COURSE_IDX      => 'CourseIndex',
        HEADING         => 'Heading',
        IMAGE           => 'Image',
        MARKDOWN        => 'Markdown',
        MODULE_IDX      => 'ModuleIndex',
        PARAGRAPH       => 'Paragraph',
        PDF             => 'PDF',
        TEST            => 'Test',
        VIDEO           => 'Video',
    },
};

enum ComponentType => [keys %{_TYPES()}];

has _type        => (is => 'ro', isa => 'Maybe[ComponentType]', init_arg => 'type');
has _olc_page_id => (is => 'ro', isa => 'Maybe[Int]',           init_arg => 'olc_page_id');
has id           => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_id');
has dbh          => (is => 'ro', required => 1);

has _component => (is => 'ro', lazy => 1, builder => '_build_component', init_arg => undef, handles => [qw(
    name build_order data_version olc_page_id type data view_data
)]);

sub create_or_update {
    my $self = shift;

    $self->_component->create_or_update;
    $self->_set_id($self->_component->id);
}

sub _build_component {
    my $self = shift;

    my $type;
    if($self->id) {
        $type = $self->dbh->resultset('OLCComponent')->find($self->id)->type;
    }
    else {
        $type = $self->_type;
    }

    my $class = 'CRP::Model::OLC::Component::' . _TYPES->{$type};
    my $component = $class->new({dbh => $self->dbh, id => $self->id});
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

