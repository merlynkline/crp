package CRP::Model::Schema::Result::CourseType;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Carp;

use DateTime;

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('course_type');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'course_type_id_seq',
        is_numeric          => 1,
        auto_nextval        => 1,
    },
    description => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    abbreviation => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    qualification_required_id => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('qualification' => 'CRP::Model::Schema::Result::Qualification', 'qualification_required_id');
__PACKAGE__->has_many('instructor_qualification' => 'CRP::Model::Schema::Result::InstructorQualification', {'foreign.qualification_id' => 'self.qualification_required_id'} );

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    foreach my $column (qw(qualification_required_id)) {
        $sqlt_table->add_index(name => "qualification_${column}_idx", fields => [$column]);
    }
}


1;

