package CRP::Model::Schema::Result::OLCStudent;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('olc_student');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'olc_student_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    id_type => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    id_foreign_key => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    course_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    status => {
        data_type           => 'text',
    },
    start_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        is_nullable         => 1,
    },
    last_access_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        is_nullable         => 1,
    },
    completion_date => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        is_nullable         => 1,
    },
    name => {
        data_type           => 'text',
    },
    email => {
        data_type           => 'text',
    },
    progress => {
        data_type           => 'text',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('course' => 'CRP::Model::Schema::Result::OLCCourse', {'foreign.id' => 'self.course_id'});

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => "student_identity_idx", fields => [qw(course_id id_type id_foreign_key)]);
}

1;

