package CRP::Model::Schema::Result::InstructorQualification;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Carp;

use DateTime;

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('instructor_qualification');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'instructor_qualification_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    qualification_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    instructor_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    passed_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        is_nullable         => 1,
    },
    trainer_id => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('instructor' => 'CRP::Model::Schema::Result::Login', 'instructor_id');
__PACKAGE__->belongs_to('qualification' => 'CRP::Model::Schema::Result::Qualification', 'qualification_id');
__PACKAGE__->belongs_to('trainer' => 'CRP::Model::Schema::Result::Login', 'trainer_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(qualification_id instructor_id)) {
        $sqlt_table->add_index(name => "qualification_${column}_idx", fields => [$column]);
    }
}

sub is_trainee {
    my $self = shift;
    return ! defined $self->passed_date || $self->passed_date > DateTime->now;
}

1;

