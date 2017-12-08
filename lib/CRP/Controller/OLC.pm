package CRP::Controller::OLC;

use Mojo::Base 'Mojolicious::Controller';

use CRP::Model::OLC::Course;
use CRP::Model::OLC::Module;
use CRP::Model::OLC::Page;
use CRP::Model::OLC::Student;
use CRP::Model::OLC::StudentProgress;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $c = shift;

    my $student = CRP::Model::OLC::Student->new;
    $c->_student_record($student);

    return 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub show_page {
    my $c = shift;

    my $failure_code = $c->_validate_page_id_params;
    return $c->_not_found($failure_code) if $failure_code;

    my $page_index = $c->_decode_and_limit_page_index($c->_course->module_page_index($c->_module, $c->_page), $c->_progress_record);

    $c->stash(
        page            => $c->_page->view_data($c->_module, $c->_course),
        module          => $c->_module->view_data,
        course          => $c->_course->view_data,
        student         => $c->_student_record->view_data,
        page_index      => $page_index,
        progress        => $c->_progress_record->view_data($c->_page),
        max_page_index  => List::Util::min($c->_progress_record->completed_pages_count + 1, $c->_course->page_count),
    );

    $c->render(template => 'olc/page');
}

sub _validate_page_id_params {
    my $c = shift;

    return 'COURSE' unless $c->_course && $c->_course->exists;
    $c->_progress_record(CRP::Model::OLC::StudentProgress->new({student => $c->_student_record, course => $c->_course}));

    $c->_decode_page_index_indicator($c->stash('module_id'), $c->_progress_record);
    return 'MODULE' unless $c->_module && $c->_module->exists;
    return 'PAGE' unless $c->_page && $c->_page->exists;

    return;
}

my $_cached_student_record;
sub _student_record {
    my $c = shift;
    ($_cached_student_record) = @_ if @_;

    return $_cached_student_record;
}

my $_cached_progress_record;
sub _progress_record {
    my $c = shift;
    ($_cached_progress_record) = @_ if @_;

    return $_cached_progress_record;
}

sub _decode_page_index_indicator {
    my $c = shift;
    my($page_index_indicator, $progress) = @_;

    return unless $page_index_indicator =~ /^x(\d+)/i;
    $c->_decode_and_limit_page_index($1, $progress);
}

sub _decode_and_limit_page_index {
    my $c = shift;
    my($page_index, $progress) = @_;

    my $course = $c->_course;

    $page_index //= 1;
    $page_index = 1 if $page_index < 1;

    my $max_allowed_page_index = List::Util::min $progress->completed_pages_count + 1, $course->page_count;
    $page_index = $max_allowed_page_index if $page_index > $max_allowed_page_index;

    $c->stash(
        page_id     => $course->page_id_from_page_index($page_index),
        module_id   => $course->module_id_from_page_index($page_index),
    );

    return $page_index;
}

my $_cached_course;
sub _course {
    my $c = shift;

    my $course_id = $c->stash('course_id') || 0;
    return $_cached_course if $_cached_course && $_cached_course->id == $course_id;
    $_cached_course = CRP::Model::OLC::Course->new(id => $course_id, dbh => $c->crp->model);

    return $_cached_course;
}

my $_cached_module_course_id;
my $_cached_module;
sub _module {
    my $c = shift;

    my $module_id = $c->stash('module_id') || 0;
    my $course = $c->_course;
    return $_cached_module if $_cached_module && $_cached_module->id == $module_id && $course->id == $_cached_module_course_id;
    my $_cached_module = CRP::Model::OLC::Module->new(id => $module_id, dbh => $c->crp->model);
    $_cached_module = $course->default_module unless $_cached_module->exists && $course->has_module($_cached_module);
    $_cached_module_course_id = $course->id;

    return $_cached_module;
}

my $_cached_page_module_id;
my $_cached_page;
sub _page {
    my $c = shift;

    my $page_id = $c->stash('page_id') || 0;
    my $module = $c->_module;
    return $_cached_page if $_cached_page && $_cached_page->id == $page_id && $module->id == $_cached_page_module_id;
    my $_cached_page = CRP::Model::OLC::Page->new(id => $page_id, dbh => $c->crp->model);
    $_cached_page = $module->default_page unless $_cached_page->exists && $module->has_page($_cached_page);
    $_cached_page_module_id = $module->id;

    return $_cached_page;
}

sub _not_found {
    my $c = shift;
    my($reason) = @_;

    $c->stash(reason => $reason);
    return $c->render(template => 'olc/not_found', status => 404);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub check_page {
    my $c = shift;

    my $failure_code = $c->_validate_page_id_params;
    return $c->_not_found($failure_code) if $failure_code;

    my $pass = 1;
    foreach my $question (@{$c->_page->questions}) {
        my $answer = $c->crp->trimmed_param($question->field_name);
        $pass = 0 unless $question->is_good_answer($answer);
    }


}

1;
