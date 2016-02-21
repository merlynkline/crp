package CRP::Model::Schema::Result::InstructorCourse;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Carp;

use CRP::Util::Types;
use DateTime;

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('instructors_course');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'instructors_course_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    instructor_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    location => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    latitude => {
        data_type           => 'real',
        is_nullable         => 1,
    },
    longitude => {
        data_type           => 'real',
        is_nullable         => 1,
    },
    venue => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    description => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    start_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        default_value       => \'(now())',
        is_nullable         => 0,
    },
    price => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    canceled => {
        data_type           => 'boolean',
        is_nullable         => 0,
    },
    published => {
        data_type           => 'boolean',
        is_nullable         => 0,
    },
    qualification_id => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('instructor' => 'CRP::Model::Schema::Result::Login', 'instructor_id');
__PACKAGE__->belongs_to('qualification' => 'CRP::Model::Schema::Result::Qualification', 'qualification_id');

my %TYPE = (
    venue               => {MinLen => 1, MaxLen => 50},
    description         => {MinLen => 1, MaxLen => 200},
    time                => {MinLen => 1, MaxLen => 20},
    price               => {MinLen => 1, MaxLen => 50},
);

sub set_column {
    my $self = shift;
    my($column, $value) = @_;

    return if $self->published && ($column eq 'location' || $column eq 'start_date');

    CRP::Util::Types::type_check($TYPE{$column}, $value) if exists $TYPE{$column};

    $self->SUPER::set_column($column, $value);
}

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(latitude longitude instructor_id)) {
        $sqlt_table->add_index(name => "instructor_course_${column}_idx", fields => [$column]);
    }
}

sub is_editable_by_instructor {
    my $self = shift;
    my($instructor_id) = @_;

    return 1 if $self->instructor_id == $instructor_id && ! $self->canceled;
    return;
}

sub is_cancelable_by_instructor {
    my $self = shift;
    my($instructor_id) = @_;

    return 1 if $self->instructor_id == $instructor_id && $self->published;
    return;
}

sub is_publishable {
    my $self = shift;

    return
        $self->start_date > DateTime->now()
        && $self->venue
        && $self->price
        && $self->description
        ;
}

sub publish {
    my $self = shift;

    croak "Instructors course is not publishable" unless $self->is_publishable;
    $self->update({published => 1, canceled => 0});
}

sub cancel {
    my $self = shift;
    my($instructor_id) = @_;

    croak "Instructors course is not cancelable" unless $self->is_cancelable_by_instructor($instructor_id);
    $self->update({canceled => 1});
}


1;

