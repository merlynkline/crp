package CRP::Model::OLC::Student;

use Moose;
use namespace::autoclean;

use Carp;
use DateTime;
use Mojo::JSON qw(decode_json encode_json);

use CRP::Model::OLC::Course;
use CRP::Model::OLC::Page;
use CRP::Model::OLC::ComponentSet::AssignmentsForPage;

use constant {
    _RESULTSET_NAME     => 'OLCStudent',
    _DELEGATED_FIELDS   => [qw(status start_date last_access_date completion_date email name)],
    _LOCAL_FIELDS       => [qw(id_type id_foreign_key course_id)],
    _PROGRESS_DATA_TYPE => {
        completed_pages_count => 'Int',
        current_answer        => {
            "<page_id>" => {
                "<component_id>" => ['Str'],
            },
        },
        assignment_passed     => {
            "<page_id>" => {
                "<component_id>" => 'Str',
            },
        },
    },
    _VALID_STATUS       => {
        COMPLETED   => 'Course completed and passed',
        PENDING     => 'Awaiting a tutor to mark an assignment',
        IN_PROGRESS => 'Study in progress',
    },
};

has id              => (is => 'ro', isa => 'Maybe[Str]', writer => '_set_id');
has dbh             => (is => 'ro', required => 1);
has _db_record      => (is => 'ro', builder => '_build_db_record', lazy => 1, handles => _DELEGATED_FIELDS);
has id_type         => (is => 'rw', isa => 'Str');
has id_foreign_key  => (is => 'rw', isa => 'Str');
has course_id       => (is => 'rw', isa => 'Str');

sub _progress {
    my $self = shift;

    if(@_) {
        my ($data) = @_;
        $data = encode_json($data) if defined $data;
        $self->_db_record->progress($data);
    }
    my $data = $self->_db_record->progress;
    $data = decode_json($data) if $data;
    return $data || {};
}

sub _progress_field {
    my $self = shift;
    my $field = shift;

    my $data = $self->_progress;
    my $field_ref = \$data;
    my $type_ref = _PROGRESS_DATA_TYPE;
    foreach my $field_part (split '\.', $field) {
        croak "Unrecognised progress field '$field_part' in '$field'" unless $type_ref = _valid_part($type_ref, $field_part);
        $$field_ref->{$field_part} = ref $type_ref eq 'HASH' ? {} : [] unless exists $$field_ref->{$field_part} || ref $type_ref eq '';
        $field_ref = \$$field_ref->{$field_part};
    }
    if(@_) {
        $$field_ref = shift;
        # TODO: Check $data against $type_ref
        $self->_progress($data);
    }
    return $$field_ref;
}

sub _valid_part {
    my($type_ref, $field_part) = @_;

    return undef unless ref $type_ref eq 'HASH';
    return $type_ref->{$field_part} if exists $type_ref->{$field_part};
    foreach my $field_type (keys %$type_ref) {
        return $type_ref->{$field_type} if $field_type =~ /^<.+_id>$/ && $field_part =~ /^\d+$/;
    }
    return undef;
}

sub view_data {
    my $self = shift;
    my($including) = @_;

    $including //= {};

    my $template_data = {progress => $self->view_data_progress($including->{page})};
    foreach my $field ('id', @{$self->_DELEGATED_FIELDS}) {
        $template_data->{$field} = $self->$field;
    }

    $template_data->{course} = $self->course->view_data if exists $including->{course};
    $template_data->{assignments} = $self->current_page_assignments->view_data if exists $including->{assignments};

    return $template_data;
}

sub course {
    my $self = shift;

    return CRP::Model::OLC::Course->new({dbh => $self->dbh, id => $self->course_id});
}

sub current_page_assignments {
    my $self = shift;

    return CRP::Model::OLC::ComponentSet::AssignmentsForPage->new({dbh => $self->dbh, page_id => $self->last_allowed_page_id});
}

sub max_allowed_page_index {
    my $self = shift;
    my($course) = @_;

    return List::Util::min $self->completed_pages_count + 1, $course->page_count;
}

sub last_allowed_page_id {
    my $self = shift;

    my $course     = $self->course;
    my $page_index = $self->max_allowed_page_index($course);
    return $course->page_id_from_page_index($page_index);
}

sub create_or_update {
    my $self = shift;

    $self->last_access_date(DateTime->now);
    $self->create_or_update_access_unchanged;
}

sub create_or_update_access_unchanged {
    my $self = shift;

    $self->start_date(DateTime->now) unless $self->start_date;
    $self->set_status('IN_PROGRESS') unless $self->status;
    foreach my $attribute(@{$self->_LOCAL_FIELDS}) {
        $self->_db_record->$attribute($self->$attribute);
    }
    $self->_db_record->update_or_insert;
    $self->_set_id($self->_db_record->id);
}

sub view_data_progress {
    my $self = shift;
    my($page) = @_;

    my $data = {
        completed_pages_count  => $self->completed_pages_count,
    };

    if($page) {
        $data->{current_answer}     = $self->current_answer($page);
        $data->{assignment_passed}  = $self->assignment_passed($page);
    }

    return $data;
}

sub completed_pages_count {
    my $self = shift;

    return $self->_progress_field('completed_pages_count', @_) || 0;
}

sub current_answer {
    my $self = shift;
    my $page = shift;
    my $component = shift;

    my $progress_field = 'current_answer.' . $page->id;
    $progress_field .= '.' . $component->id if $component;
    return $self->_progress_field($progress_field, @_);
}

sub assignment_passed {
    my $self = shift;
    my $page = shift;
    my $component = shift;

    my $progress_field = 'assignment_passed.' . $page->id;
    $progress_field .= '.' . $component->id if $component;
    my @value = @_;
    if(@value) {
        croak 'You can only set an assignment as passed for a specific component' unless $component;
        croak "You can't set an assgnment as passed for a component type '" . $component->type . "'" unless $component->type eq 'QTUTORMARKED';
    }

    my $res = $self->_progress_field($progress_field, @value);

    $self->_match_course_pending_status_to_assignment_pending_status if @value && $value[0];

    return $res;
}

sub _match_course_pending_status_to_assignment_pending_status {
    my $self = shift;

    my $page = CRP::Model::OLC::Page->new({dbh => $self->dbh, id => $self->last_allowed_page_id});
    my $assignments = $self->current_page_assignments;
    my $status = 'IN_PROGRESS';
    foreach my $component (@{$assignments->all}) {
        next if $self->assignment_passed($page, $component);
        $status = 'PENDING';
        last;
    }
    $self->set_status($status);
}

sub set_status {
    my $self = shift;
    my($status) = @_;

    croak "Unrecognised status '$status'" unless exists _VALID_STATUS->{$status};
    return if ($self->status // '') eq $status;
    $self->status($status);
    $self->completion_date(DateTime->now) if $status eq 'COMPLETED';
}

sub _build_db_record {
    my $self = shift;

    my $resultset = $self->dbh->resultset($self->_RESULTSET_NAME);
    my $res;
    if($self->id) {
        $res = $resultset->find($self->id);
        croak "Couldn't load " . $self->_RESULTSET_NAME . " ID '" . $self->id . "'" unless $res;
        foreach my $attribute(@{$self->_LOCAL_FIELDS}) {
            $self->$attribute($res->$attribute);
        }
    }
    elsif($self->course_id && $self->id_type && $self->id_foreign_key) {
        my $identity = {
            id_foreign_key  => $self->id_foreign_key,
            id_type         => $self->id_type,
            course_id       => $self->course_id,
        };
        $res = $resultset->find($identity);
        $res = $resultset->new_result($identity) unless $res;
        $self->_set_id($res->id);
    }
    else {
        $res = $resultset->new_result({});
    }
    return $res;
}

sub BUILD {
    my $self = shift;

    $self->_db_record; # Force load
}

__PACKAGE__->meta->make_immutable;

1;

