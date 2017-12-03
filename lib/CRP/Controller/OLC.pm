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

    $c->stash(olc => {
            student_record => $student,
        });

    return 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub show_page {
    my $c = shift;

    my $module_id = $c->stash('moudule_id');
    my $page_id = $c->stash('page_id');

    my $course = $c->_course;
    return $c->_not_found('COURSE') unless $course && $course->exists;
    my $module = $c->_module;
    return $c->_not_found('MODULE') unless $module && $module->exists;
    my $page = $c->_page;
    return $c->_not_found('PAGE') unless $page && $page->exists;
    my $progress = CRP::Model::OLC::StudentProgress->new({student => $c->stash('olc')->{student_record}, course => $course});

    $c->stash(
        page        => $page->view_data($module, $course),
        module      => $module->view_data,
        course      => $course->view_data,
        student     => $c->stash('olc')->{student_record}->view_data,
        page_index  => $course->module_page_index($module, $page) + 1,
        progress    => $progress->view_data,
    );

    $c->render(template => 'olc/page');
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

1;
