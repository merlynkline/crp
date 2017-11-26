package CRP::Model::OLC::Course;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use CRP::Model::OLC::ModuleSet::ForCourse;

use constant {
    _DB_FIELDS      => [qw(name notes description title last_update_date)],
    _RESULTSET_NAME => 'OLCCourse',
};

has '+_db_record' => (handles => _DB_FIELDS);

has module_set    => (is => 'ro', lazy => 1, builder => '_build_module_set', init_arg => undef);

override view_data => sub {
    my $self = shift;

    my $data = super();
    $data->{modules} = $self->module_set->view_data;

    return $data;
};

override state_data => sub {
    my $self = shift;

    my $data = super();
    $data->{modules} = $self->module_set->state_data;

    return $data;
};

sub default_module {
    my $self = shift;

    foreach my $module (@{$self->module_set->all}) {
        my $page = $module->default_page;
        return $module if $page;
    }

    return undef;
}

sub has_module {
    my $self = shift;
    my($module) = @_;

    my $module_id = $module->id;
    return any {$_->id eq $module_id} @{$self->module_set->all};
}

sub _build_module_set {
    my $self = shift;

    return CRP::Model::OLC::ModuleSet::ForCourse->new(dbh => $self->dbh, course_id => $self->id);
}

__PACKAGE__->meta->make_immutable;

1;

