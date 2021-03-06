package CRP::Model::OLC::Component;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Carp;

use Mojo::JSON qw(decode_json);

use CRP::Model::OLC::Course;
use CRP::Model::OLC::Module;
use CRP::Model::OLC::Component::CourseIndex;
use CRP::Model::OLC::Component::Heading;
use CRP::Model::OLC::Component::Image;
use CRP::Model::OLC::Component::Markdown;
use CRP::Model::OLC::Component::ModuleIndex;
use CRP::Model::OLC::Component::PDF;
use CRP::Model::OLC::Component::Paragraph;
use CRP::Model::OLC::Component::Video;
use CRP::Model::OLC::Component::SingleOption;
use CRP::Model::OLC::Component::MultipleOption;
use CRP::Model::OLC::Component::TutorMarked;

use constant {
    _TYPE_CLASS     => {
        COURSE_IDX      => 'CourseIndex',
        HEADING         => 'Heading',
        IMAGE           => 'Image',
        MARKDOWN        => 'Markdown',
        MODULE_IDX      => 'ModuleIndex',
        PARAGRAPH       => 'Paragraph',
        PDF             => 'PDF',
        VIDEO           => 'Video',
        QPICKONE        => 'SingleOption',
        QPICKMANY       => 'MultipleOption',
        QTUTORMARKED    => 'TutorMarked',
    },
};

enum ComponentType => [keys %{_TYPE_CLASS()}];

has _type            => (is => 'ro', isa => 'Maybe[ComponentType]', writer => '_set_type', init_arg => 'type');
has _olc_page_id     => (is => 'ro', isa => 'Maybe[Int]',                                  init_arg => 'olc_page_id');
has id               => (is => 'ro', isa => 'Maybe[Str]',           writer => '_set_id');
has guid             => (is => 'ro', isa => 'Maybe[Str]',           writer => '_set_guid');
has dbh              => (is => 'ro', required => 1);
has _serialised_data => (is => 'ro', isa => 'Str',                                          init_arg => 'serialised_data');

has _component => (is => 'ro', lazy => 1, builder => '_build_component', init_arg => undef, handles => [qw(
    name build_order data_version olc_page_id type data view_data is_question is_good_answer last_update_date serialised
)]);

sub create_or_update {
    my $self = shift;
    my($as_at_date) = @_;

    $self->_component->create_or_update($as_at_date);
    $self->_set_id($self->_component->id);
    $self->_set_guid($self->_component->guid);
}

sub state_data  {
    my $self = shift;

    my $data = $self->_component->state_data(@_);
    $data->{type} = $self->type;

    return $data;
}

sub _build_component {
    my $self = shift;

    my $type;
    if($self->id) {
        $type = $self->dbh->resultset('OLCComponent')->find({id => $self->id})->type;
    }
    elsif($self->guid) {
        $type = $self->dbh->resultset('OLCComponent')->find({guid => $self->guid})->type;
    }
    else {
        $type = $self->_type;
    }

    my $class = 'CRP::Model::OLC::Component::' . _TYPE_CLASS->{$type};
    my $component = $class->new({dbh => $self->dbh, id => $self->id, guid => $self->guid});
    unless($self->id || $self->guid) {
        $component->olc_page_id($self->_olc_page_id);
        $component->type($self->_type);
    }

    return $component;
}

sub deserialise {
    my $self = shift;
    my($serialised_data) = @_;

    my $data = decode_json($serialised_data);
    $self->_set_type($data->{type});
    $self->_component->deserialise($serialised_data);
}

sub BUILD {
    my $self = shift;

    $self->_component if $self->guid || $self->id; # Force load to validate
    $self->deserialise($self->_serialised_data) if $self->_serialised_data;
    return if $self->id || $self->guid;
    return if $self->olc_page_id && $self->type;
    croak __PACKAGE__ . ' requires an id, a guid or both an olc_page_id and a type';
}

__PACKAGE__->meta->make_immutable;

1;

