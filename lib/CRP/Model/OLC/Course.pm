package CRP::Model::OLC::Course;
use Moose;
use namespace::autoclean;

extends 'CRP::Model::DBICIDObject';

use List::Util;

use CRP::Model::OLC::ModuleSet::ForCourse;

use constant {
    _DB_FIELDS      => [qw(name notes description title last_update_date)],
    _RESULTSET_NAME => 'OLCCourse',
};

has '+_db_record' => (handles => _DB_FIELDS);

has module_set    => (is => 'ro', lazy => 1, builder => '_build_module_set', init_arg => undef, handles => [qw(page_count)]);

override view_data => sub {
    my $self = shift;

    my $data = {
        %{super()},
        modules     => $self->module_set->view_data,
        page_count  => $self->page_count,
    };

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
    return List::Util::any { $_->id eq $module_id} @{$self->module_set->all};
}

sub module_page_index {
    my $self = shift;
    my($module, $page) = @_;

    my $module_page = $module->id . ':' . $page->id;
    my $module_page_list = $self->module_set->module_page_list;
    return ( List::Util::first { $module_page_list->[$_] eq $module_page } (0 .. $#$module_page_list) ) + 1;
}

sub module_id_from_page_index {
    my $self = shift;
    my($page_index) = @_;

    my $module_page = $self->_module_page_from_page_index($page_index);
    $module_page =~ s/:.+$//;
    return $module_page;
}

sub page_id_from_page_index {
    my $self = shift;
    my($page_index) = @_;

    my $module_page = $self->_module_page_from_page_index($page_index);
    $module_page =~ s/^.+://;
    return $module_page;
}

sub _module_page_from_page_index {
    my $self = shift;
    my($page_index) = @_;

    my $module_page_list = $self->module_set->module_page_list;
    $page_index = 1 if ($page_index // 0) < 1;
    $page_index = @$module_page_list if $page_index > @$module_page_list;
    return $module_page_list->[$page_index - 1];
}

sub _build_module_set {
    my $self = shift;

    return CRP::Model::OLC::ModuleSet::ForCourse->new(dbh => $self->dbh, course_id => $self->id);
}

__PACKAGE__->meta->make_immutable;

1;

