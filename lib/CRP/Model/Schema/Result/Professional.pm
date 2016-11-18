package CRP::Model::Schema::Result::Professional;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Carp;

use DateTime;
use CRP::Util::WordNumber;

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('professional');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'professional_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    name => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    organisation_name => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    organisation_address => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    organisation_postcode => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    organisation_telephone => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    email => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    instructors_course_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    is_suspended => {
        data_type           => 'boolean',
        default_value       => 'f',
        is_nullable         => 0,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('instructors_course' => 'CRP::Model::Schema::Result::InstructorCourse', 'instructors_course_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(email name)) {
        $sqlt_table->add_index(name => "professional_${column}_idx", fields => [$column]);
    }
}

sub slug {
    my $self = shift;

    return CRP::Util::WordNumber::encode_number($self->id);
}

sub signature {
    my $self = shift;

    return '-' . CRP::Util::WordNumber::encipher($self->id);
}

sub is_trained {
    my $self = shift;

    return $self->instructors_course->start_date < DateTime->now;
}

1;

