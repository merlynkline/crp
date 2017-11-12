package CRP::Model::OLC::Component;
# TODO:Break this up into a module per component type
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Carp;

use Mojo::JSON qw(decode_json encode_json);

use CRP::Model::OLC::UntypedComponent;
use CRP::Model::OLC::Course;
use CRP::Model::OLC::Module;

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
        MARKDOWN        => 1,
    },
};

enum ComponentType => [keys %{_TYPES()}];

has _type        => (is => 'ro', isa => 'Maybe[ComponentType]', init_arg => 'type');
has _olc_page_id => (is => 'ro', isa => 'Maybe[Int]',           init_arg => 'olc_page_id');
has id           => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_id');
has dbh          => (is => 'ro', required => 1);

has _component => (is => 'ro', lazy => 1, builder => '_build_component', init_arg => undef, handles => [qw(
    name build_order data_version olc_page_id type
)]);

sub create_or_update {
    my $self = shift;

    $self->_component->create_or_update;
    $self->_set_id($self->_component->id);
}

sub view_data {
    my $self = shift;
    my($module_context, $course_context) = @_;

    my $data = $self->_component->view_data;
    my $type = $self->type // '';
    if($type eq 'HEADING') {
        my $preview = $data->{heading_text} = $self->data;
        $data->{preview} = substr $preview, 0, 50;
    }
    elsif($type eq 'PARAGRAPH') {
        my $preview = $data->{paragraph_text} = $self->data;
        $preview =~ s/<.*?>/ /g;
        $preview =~ s/\&.*?;/ /g;
        $preview =~ s/\s+/ /g;
        $data->{preview} = substr $preview, 0, 50;
    }
    elsif($type eq 'MARKDOWN') {
        my $preview = $data->{markdown_text} = $self->data;
        $preview =~ s/\s+/ /g;
        $data->{preview} = substr $preview, 0, 50;
    }
    elsif($type eq 'COURSE_IDX') {
        confess "You must supply a course context" unless ref $course_context eq 'CRP::Model::OLC::Course';
        $data->{course} = $course_context->view_data;
        $data->{preview} = $course_context->name;
    }
    elsif($type eq 'MODULE_IDX') {
        confess "You must supply a module context" unless ref $module_context eq 'CRP::Model::OLC::Module';
        $data->{module} = $module_context->view_data;
        $data->{preview} = $module_context->name;
    }
    elsif($type eq 'IMAGE') {
        my $component_data = $self->data;
        my $preview = $data->{image_path} = $component_data->{path} // '';
        $data->{image_format} = $component_data->{format} // '';
        $data->{image_file} = $component_data->{file} // '';
        $preview =~ s{^.+/}{};
        $data->{preview} = $preview;
    }

    return $data;
}

sub data {
    my $self = shift;

    my $data;
    if(@_) {
        ($data) = @_;
        my $encoded_data = $data;
        if($self->type eq 'IMAGE') {
            $encoded_data = encode_json($data) if $data;
        }
        $self->_component->data($encoded_data);
    }
    else {
        $data = $self->_component->data;
        if($self->type eq 'IMAGE') {
            $data = decode_json($data) if $data;
            $data ||= {};
        }
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

