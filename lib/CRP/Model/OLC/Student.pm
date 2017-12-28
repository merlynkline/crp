package CRP::Model::OLC::Student;

use Moose;
use namespace::autoclean;

use Carp;
use DateTime;
use Mojo::JSON qw(decode_json encode_json);

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
    my($page) = @_;

    my $template_data = {progress => $self->view_data_progress($page)};
    foreach my $field ('id', @{$self->_DELEGATED_FIELDS}) {
        $template_data->{$field} = $self->$field;
    }
    return $template_data;
}

sub create_or_update {
    my $self = shift;

    $self->last_access_date(DateTime->now);
    $self->status('IN_PROGRESS') unless $self->status;
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
        $data->{current_answer} = $self->current_answer($page);
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
    $progress_field .= '.' . $component->idi if $component;
    return $self->_progress_field($progress_field, @_);
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
    #        croak "Couldn't load " . $self->_RESULTSET_NAME . " FKID '" . $self->id_foreign_key . "', TYPE '" . $self->id_type . "', CID '" . $self->course_id . "'" unless $res;
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

