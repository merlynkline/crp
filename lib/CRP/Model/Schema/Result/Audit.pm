package CRP::Model::Schema::Result::Audit;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('audit');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'course_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    timestamp => {
        data_type           => 'timestamptz',
        timezone            => 'UTC',
        default_value       => \'(now())',
        is_nullable         => 0,
    },
    course_id => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
    instructor_id => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
    event_type => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    details => {
        data_type           => 'text',
        is_nullable         => 0,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('course' => 'CRP::Model::Schema::Result::Login', 'course_id');
__PACKAGE__->belongs_to('instructor' => 'CRP::Model::Schema::Result::Login', 'instructor_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(instructor_id course_id timestamp)) {
        $sqlt_table->add_index(name => "profile_${column}_idx", fields => [$column]);
    }
}

1;

