package CRP::Controller::OLC;

use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

use CRP::Model::OLC::Course;
use CRP::Model::OLC::Module;
use CRP::Model::OLC::Page;
use CRP::Model::OLC::Student;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $c = shift;

    my $identity;
    my $authorised = 0;

    my $student_id = $c->session('olc_student_id');
    if($student_id) {
        my $student;
        try {
            $student = CRP::Model::OLC::Student->new(id => $student_id, dbh => $c->crp->model);
            if($student->course_id == $c->_course_id) {
                $c->_authorised_student($student);
                $authorised = 1;
            }
            else {
                $identity = {
                    type    => $student->id_type,
                    key     => $student->id_foreign_key,
                };
            }
        };
    }

    unless($authorised) {

        $identity = $c->_tcrp_identity unless $identity;

        if($identity) {
            $c->_check_authority_and_get_details($identity);
            if($identity->{authorised}) {
                my $student = $c->_student_from_identity($identity);
                $c->_authorised_student($student);
                $authorised = 1;
            }
        }
    }

    $c->redirect_to('crp.login') unless $authorised;
    return $authorised;
}

sub _authorised_student {
    my $c = shift;
    my($student) = @_;

    $c->_student_record($student);
    $student->create_or_update;
    $c->session(olc_student_id => $student->id);
}

sub _student_from_identity {
    my $c = shift;
    my($identity) = @_;

    my $student = CRP::Model::OLC::Student->new(
        dbh             => $c->crp->model,
        id_type         => $identity->{type},
        id_foreign_key  => $identity->{key},
        course_id       => $c->_course_id,
    );
    $student->name($identity->{name});
    $student->email($identity->{email});
    return $student;
}

sub _tcrp_identity {
    my($c) = @_;

    my $key = $c->crp->logged_in_instructor_id;
    return {
        type    => 'TCRP',
        key     => $key,
    } if($key);

    return undef;
}

sub _check_authority_and_get_details {
    my $c = shift;
    my($identity) = @_;

    $c->_check_authority_and_get_details_tcrp($identity) if $identity->{type} eq 'TCRP';
}

sub _check_authority_and_get_details_tcrp {
    my $c = shift;
    my($identity) = @_;

    my $profile = $c->crp->model('Profile')->find({instructor_id => $identity->{key}});
    return unless $profile;

    my $authorised = $profile->login->is_administrator;

    unless($authorised) {
        my $course_code = $c->_course->code;
        my @qualificatons = $profile->login->qualifications;
        foreach my $instructor_qualification (@qualificatons) {
            my $olc_codes = $instructor_qualification->qualification->olccodes // '';
            if(index(",$olc_codes,", ",$course_code,") >= 0) {
                $authorised = 1;
                last;
            }
        }
    }

    @$identity{qw(authorised name email)} = (1, $profile->name, $profile->login->email) if $authorised;

    return;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub show_page {
    my $c = shift;

    my $failure_code = $c->_validate_page_id_params;
    return $c->_not_found($failure_code) if $failure_code;

    my $page_index = $c->_decode_and_limit_page_index($c->_course->module_page_index($c->_module, $c->_page), $c->_student_record);

    $c->stash(
        page                => $c->_page->view_data($c->_module, $c->_course),
        module              => $c->_module->view_data,
        course              => $c->_course->view_data,
        student             => $c->_student_record->view_data($c->_page),
        page_index          => $page_index,
        error_component_ids => { map { $_ => 1 } split ',', $c->flash('error_component_ids') // '' },
        max_page_index      => List::Util::min($c->_student_record->completed_pages_count + 1, $c->_course->page_count),
    );
    $c->_set_page_accessibility_flags;

    $c->render(template => 'olc/page');
}

sub _set_page_accessibility_flags {
    my $c = shift;

    my $completed_pages_count = $c->_student_record->completed_pages_count;

    my $module_start_page_index = 0;
    my $current_module_id = $c->_module->id;
    my $course_data = $c->stash('course');
    foreach my $module_data (@{$course_data->{modules}}) {
        last if $module_data->{id} == $current_module_id;
        $module_start_page_index += @{$module_data->{pages}};
    }

    my $page_data = $c->stash('page');
    foreach my $component_data (@{$page_data->{components}}) {
        if($component_data->{type} eq 'COURSE_IDX') {
            my $page_index = 0;
            foreach my $module_data (@{$component_data->{course}->{modules}}) {
                foreach my $page_data (@{$module_data->{pages}}) {
                    $page_data->{_accessible} = $page_index <= $completed_pages_count;
                    $page_index++;
                }
            }
        }
        elsif($component_data->{type} eq 'MODULE_IDX') {
            my $page_index = $module_start_page_index;
            foreach my $page_data (@{$component_data->{module}->{pages}}) {
                $page_data->{_accessible} = $page_index <= $completed_pages_count;
                $page_index++;
            }
        }
    }
}

sub _validate_page_id_params {
    my $c = shift;

    return 'COURSE' unless $c->_course && $c->_course->exists;

    $c->_decode_page_index_indicator($c->stash('module_id'), $c->_student_record);
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

sub _decode_page_index_indicator {
    my $c = shift;
    my($page_index_indicator, $student) = @_;

    return unless $page_index_indicator && $page_index_indicator =~ /^x(\d+)/i;
    $c->_decode_and_limit_page_index($1, $student);
}

sub _decode_and_limit_page_index {
    my $c = shift;
    my($page_index, $student) = @_;

    my $course = $c->_course;

    $page_index //= 1;
    $page_index = 1 if $page_index < 1;

    my $max_allowed_page_index = List::Util::min $student->completed_pages_count + 1, $course->page_count;
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

    my $course_id = $c->_course_id;
    return $_cached_course if $_cached_course && $_cached_course->id == $course_id;
    $_cached_course = CRP::Model::OLC::Course->new(id => $course_id, dbh => $c->crp->model);

    return $_cached_course;
}

sub _course_id {
    my $c = shift;

    return $c->stash('course_id') || 0;
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
    my @error_component_ids;
    my $current_answer = {};
    foreach my $component (@{$c->_page->component_set->all}) {
        next unless $component->is_question;
        my $answer = $c->every_param('answer-' . $component->id);
        $c->_student_record->current_answer($c->_page, $component, $answer);
        unless($component->is_good_answer($answer)) {
            push @error_component_ids, $component->id;
            $pass = 0;
        }
    }

    my $next_page_index = $c->_course->module_page_index($c->_module, $c->_page);
    if($pass) {
        $c->_student_record->completed_pages_count($next_page_index);
        ++$next_page_index;
    }
    $c->_student_record->create_or_update;

    my $url = $c->url_for('crp.olc.showmodule', {module_id => "X$next_page_index"});
    $url->fragment('anchor-' . $error_component_ids[0]) if @error_component_ids;
    $c->flash(error_component_ids => join ',', @error_component_ids);
    return $c->redirect_to($url);
}

1;
