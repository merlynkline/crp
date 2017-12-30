package CRP::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;

use Try::Tiny;
use DateTime;
use CRP::Util::DateParser;
use CRP::Util::WordNumber;
use CRP::Util::Misc;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $c = shift;

    return 1 if $c->stash('login_record')->is_administrator && ! $c->stash('login_record')->is_demo;
    $c->render(text => "Sorry - you aren't authorised to see this page", status => 403);
    return 0;
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    my $days = $c->config->{course}->{age_when_advert_expires_days};
    $c->stash(
        instructor_count                     => $c->crp->model('Profile')->search_live_profiles->count,
        trainee_instructor_count             => $c->crp->model('Profile')->search_trainees->count,
        qualified_instructor_count           => $c->crp->model('Profile')->search_qualified->count,
        draft_courses_count                  => $c->crp->model('Course')->get_draft_set->count,
        advertised_courses_count             => $c->crp->model('Course')->get_advertised_set($days)->count,
        past_courses_count                   => $c->crp->model('Course')->get_past_set($days)->count,
        draft_instructor_courses_count       => $c->crp->model('InstructorCourse')->get_draft_set->count,
        advertised_instructor_courses_count  => $c->crp->model('InstructorCourse')->get_advertised_set($days)->count,
        past_courses_instructor_count        => $c->crp->model('InstructorCourse')->get_past_set($days)->count,
        available_qualifications             => [ $c->crp->model('Qualification')->search(undef, {order_by => 'abbreviation'}) ],
    );
    $c->render(template => "admin/welcome");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub list_parent_courses {
    my $c = shift;

    my $type = $c->param('type') || 'all';
    my $instructor_id = $c->param('id');
    my $courses = $c->crp->model('Course');

    $c->_stash_course_list_info($courses, $type, $instructor_id);

    return $c->page('parent_courses');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub list_instructor_courses {
    my $c = shift;

    my $type = $c->param('type') || 'all';
    my $instructor_id = $c->param('id');
    my $courses = $c->crp->model('InstructorCourse');

    $c->_stash_course_list_info($courses, $type, $instructor_id);

    return $c->page('instructor_courses');
}

sub _stash_course_list_info {
    my $c = shift;
    my($courses, $type, $instructor_id) = @_;

    my $days = $c->config->{course}->{age_when_advert_expires_days};

    my $set;
    if   ($type eq 'advertised') { $set = $courses->get_advertised_set($days); }
    elsif($type eq 'draft')      { $set = $courses->get_draft_set;             }
    elsif($type eq 'past')       { $set = $courses->get_past_set($days);       }
    elsif($type eq 'canceled')   { $set = $courses->get_canceled_set($days);   }
    else                         { $set = $courses->resultset;                 }

    if($instructor_id) {
        $set = $set->search({ instructor_id => $instructor_id });
        my $login = $c->crp->model('Login')->find($instructor_id);
        $c->stash(login => $login);
        my $profile = $login->profile;
        $c->stash(profile_record => $profile) if $profile;
    }

    $c->stash(
        instructor_id   => $instructor_id,
        type            => $type,
        course_list     => [ $set->search(undef, { order_by => {-asc => 'start_date'} }) ],
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');
    $c->stash('page', $page);

    $c->render(template => "admin/pages/$page", @_);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub find_account {
    my $c = shift;

    my $validation = $c->validation;
    $validation->required('query');
    my $query = $c->crp->trimmed_param('query');
    $query =~ s{^ [%\s]+ | [\s%]+ $}{}gsmx; # Prevent match-all searches
    $validation->error(query => ['like']) unless $query;
    return $c->_find_account_results($query) if( ! $validation->has_error);
    return $c->welcome;
}

sub _find_account_results {
    my $c = shift;
    my($query) = @_;

    my $matches;
    if($query =~ m{^-?(\d+)$}) {
        my $id = CRP::Util::WordNumber::decode_number($1);
        return $c->redirect_to($c->url_for('crp.admin.show_account')->query(id => $id)) if $id;
    }
    if($query) {
        $c->stash(search_key => $query);
        $matches = $c->_find_acounts($query);
        if($matches && @$matches == 1) {
            $c->flash(msg => 'single_match');
            return $c->_redirect_to_show_account_id($matches->[0]->id);
        }
    }
    return $c->page('find_account_results', matches => $matches);
}

sub _find_acounts {
    my $c = shift;
    my($search_key) = @_;

    my($where, @extra_joins);

    if($search_key =~ /^qualified:\s*(\d+)\s*$/i) {
        my $qualification = $1;
        $where = {
            'qualifications.qualification_id'   => { '=', $qualification },
            'qualifications.passed_date'  => [ {'<', DateTime->now} ],
        };
        @extra_joins = ('qualifications');
    }
    elsif($search_key =~ /^trainee:\s*(\d+)\s*$/i) {
        my $qualification = $1;
        $where = {
            'qualifications.qualification_id'   => { '=', $qualification },
            'qualifications.passed_date'  => [ {'>', DateTime->now}, {'=', undef} ],
        };
        @extra_joins = ('qualifications');
    }
    else {
        $where = [
            \['lower(profile.name) like ?', lc "%$search_key%"],
            \['lower(email) like  ?', lc "%$search_key%"],
        ];
    }

    my @matches = $c->crp->model('Login')->search(
        $where,
        {
            join     => [qw(profile), @extra_joins],
            order_by => {-asc => \['lower(email)']}
        },
    );

    return \@matches if @matches;
    return;
}

sub _redirect_to_show_account_id {
    my $c = shift;
    my($id) = @_;

    return $c->redirect_to($c->url_for('crp.admin.show_account')->query(id => $id));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub show_account {
    my $c = shift;

    my $id = $c->param('id') || shift || return $c->welcome;
    my $login = $c->crp->model('Login')->find($id) || return $c->welcome;
    my $days = $c->config->{course}->{age_when_advert_expires_days};
    my $profile = $login->profile;
    $c->stash(login => $login);
    if($profile) {
        $c->stash(
            profile_record                       => $profile,
            draft_courses_count                  => $profile->courses->get_draft_set->count,
            advertised_courses_count             => $profile->courses->get_advertised_set($days)->count,
            past_courses_count                   => $profile->courses->get_past_set($days)->count,
            draft_instructor_courses_count       => $profile->instructors_courses->get_draft_set->count,
            advertised_instructor_courses_count  => $profile->instructors_courses->get_advertised_set($days)->count,
            past_courses_instructor_count        => $profile->instructors_courses->get_past_set($days)->count,
            instructors_trained                  => [ $c->crp->model('InstructorQualification')->search({trainer_id => $id}, {order_by => 'passed_date'}) ],
        );
    }
    $c->stash(available_qualifications => [ $c->crp->model('Qualification')->search(undef, {order_by => 'abbreviation'}) ]);
    my $trainers = [ $c->crp->model('CourseType')->search(
        {
            qualification_earned_id => { '!=', undef },
        },
        {
            join     => {'instructor_qualification' => {'instructor' => 'profile'}},
            select   => [ 'profile.instructor_id', 'profile.name'],
            as       => [ 'instructor_id', 'name'],
            distinct => 1,
        }
    )];
    $trainers = [ map { [$_->get_column('name') => $_->get_column('instructor_id')] } @$trainers ];
    $c->stash(trainers => $trainers);
    return $c->page('show_account');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub create_account {
    my $c = shift;

    if($c->req->method eq 'POST') {
        my $email = $c->_get_and_validate_instructor_email_param();
        my $name = $c->crp->trimmed_param('name');
        my $validation = $c->validation;
        $validation->required('name')->like(qr{\S+});
        return $c->welcome if $validation->has_error;

        my $login_record = $c->crp->model('Login')->create({email => $email});

        my $profile = $c->crp->model('Profile')->find_or_create({instructor_id => $login_record->id});
        $profile->name($name);
        $profile->update;

        $c->flash(msg => 'account_create');
        return $c->_redirect_to_show_account_id($login_record->id);
    }
    return $c->page('show_account');
}

sub _get_and_validate_instructor_email_param {
    my $c = shift;

    my $email = $c->_get_and_validate_email_param();
    my $validation = $c->validation;
    unless($validation->has_error) {
        my $login_record = $c->crp->model('Login')->search(\['lower(me.email) = ?', lc $email])->first;
        $validation->error(email => ['duplicate_email']) if $login_record;
    }
    return $email;
}

sub _get_and_validate_email_param {
    my $c = shift;

    my $email = $c->crp->trimmed_param('email');
    my $validation = $c->validation;
    $validation->required('email')->like(qr{^.+@.+[.].+});
    return $email;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDFMarkUp;
use CRP::Util::CRPDataFormatter;
sub certificate {
    my $c = shift;

    my $id = $c->param('id') || shift || return $c->welcome;
    my $code = $c->param('code') || '';
    my $login = $c->crp->model('Login')->find($id) || return $c->welcome;
    my $pdf = $c->app->home->rel_file("pdfs/Qualification_Certificate_$code.pdf")->to_string;
    return $c->reply->not_found unless -r $pdf;

    my $pdf_doc = CRP::Util::PDFMarkUp->new(file_path => $pdf);
    my $signature = '-' . CRP::Util::WordNumber::encipher($login->id);
    my $data = {
        signature       => $signature,
        signature_url   => $c->url_for('crp.membersite.certificate', slug => $signature)->to_abs,
    };
    $c->render_file(
        data                => $pdf_doc->fill_template($data),
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
        filename            => $pdf_doc->filename,
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub change_demo {
    my $c = shift;

    my $id = $c->param('id') || shift || return $c->welcome;
    my $login = $c->crp->model('Login')->find($id) || return $c->welcome;
    $login->is_demo($login->is_demo ? 0 : 1);
    $login->update;
    return $c->_redirect_to_show_account_id($id);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub change_email {
    my $c = shift;

    my $id = $c->param('id') || shift || return $c->welcome;
    my $email = $c->_get_and_validate_instructor_email_param();
    my $validation = $c->validation;
    return $c->show_account($id) if $validation->has_error;
    my $login = $c->crp->model('Login')->find($id) || return $c->welcome;
    $login->email($email);
    $login->update;
    $c->flash(msg => 'email_updated');
    return $c->_redirect_to_show_account_id($id);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub add_instructor_qualification {
    my $c = shift;

    my $id = $c->param('id') || shift || return $c->welcome;
    my $validation = $c->validation;

    my $qualification_id = $c->param('qualification');
    $validation->error(qualification => ['no_qualification']) unless $qualification_id ne '' && $c->crp->model('Qualification')->find($qualification_id);
    my $trainer_id = $c->param('trainer');
    if($trainer_id ne '' && $c->crp->model('Login')->find($trainer_id)) {
        if($qualification_id) {
            unless(_trainer_can_teach_qualification($c, $trainer_id, $qualification_id)) {
                $validation->error(trainer => ['trainer_not_qualified']);
            }
        }
    }
    else {
        $validation->error(trainer => ['no_trainer']) unless $trainer_id ne '' && $c->crp->model('Login')->find($trainer_id);
    }
    if( ! $validation->has_error) {
        my $has_qualification = $c->crp->model('InstructorQualification')->search({
                instructor_id       => $id,
                qualification_id    => $qualification_id,
            })->count > 0;
        $validation->error(qualification => ['has_qualification']) if $has_qualification;
    }

    my $pass_date = CRP::Util::Misc::get_date_input($c->crp->trimmed_param('pass_date'));

    return $c->show_account($id) if $validation->has_error;

    $c->crp->model('InstructorQualification')->create({
            instructor_id       => $id,
            qualification_id    => $qualification_id,
            trainer_id          => $trainer_id,
            passed_date         => $pass_date,
        });

    $c->flash(msg => 'qualification_added');
    return $c->_redirect_to_show_account_id($id);
}

sub _trainer_can_teach_qualification {
    my($c, $trainer_id, $qualification_id) = @_;

    # Logged-in admin can teach anything, to boot-strap adding of qualifications
    return 1 if $c->stash('login_record')->id == $trainer_id;

    return 1 if $c->crp->model('CourseType')->search(
        {
            qualification_earned_id => $qualification_id,
            'instructor_qualification.instructor_id' => $trainer_id,
        },
        {
            join     => 'instructor_qualification'
        }
    )->count > 0;
    return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub delete_instructor_qualification {
    my $c = shift;

    my $id = $c->param('id') || return $c->welcome;
    my $qualification_id = $c->param('qid') || return $c->welcome;
    my $sure = $c->param("sure$qualification_id") // '';
    my $validation = $c->validation;

    $validation->error("sure$qualification_id", ['confirm_delete']) unless $sure eq 'Y';
    return $c->show_account($id) if $validation->has_error;

    $c->crp->model('InstructorQualification')->find({
                instructor_id   => $id,
                id              => $qualification_id,
            })->delete;

    $c->flash(msg => 'qualification_deleted');
    return $c->_redirect_to_show_account_id($id);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub set_pass_date {
    my $c = shift;
    my $id = $c->param('id') || return $c->welcome;
    my $qualification_id = $c->param('qid') || return $c->welcome;
    my $validation = $c->validation;

    my $pass_date = CRP::Util::Misc::get_date_input($c->crp->trimmed_param("pass_date_$qualification_id"));
    $validation->error("pass_date_$qualification_id", ["no_pass_date"]) unless $pass_date;
    return $c->show_account($id) if $validation->has_error;

    my $instructor_qualification = $c->crp->model('InstructorQualification')->find({
                instructor_id   => $id,
                id              => $qualification_id,
            });

    $instructor_qualification->passed_date($pass_date);
    $instructor_qualification->update;

    $c->flash(msg => 'qualification_updated');
    return $c->_redirect_to_show_account_id($id);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub edit_qualification {
    my $c = shift;
    my $id = $c->param('id') || return $c->welcome;

    my $qualification = $c->crp->model('Qualification')->find($id) || return $c->welcome;
    $c->param(abbreviation  => $qualification->abbreviation);
    $c->param(qualification => $qualification->qualification);
    $c->param(code          => $qualification->code);
    $c->param(olccodes      => $qualification->olccodes);
    return $c->page('edit_qualification');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub add_qualification {
    my $c = shift;
    my $id = $c->param('id') && return $c->welcome;

    return $c->page('edit_qualification');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub save_qualification {
    my $c = shift;
    my $id = $c->param('id');

    my $validation = $c->validation;
    $validation->required('abbreviation');
    my $abbreviation = $c->crp->trimmed_param('abbreviation');
    $validation->error('abbreviation', ['invalid_column_MinLen']) unless length $abbreviation >= 4;
    $validation->error('abbreviation', ['invalid_column_MaxLen']) unless length $abbreviation <= 30;
    $validation->required('qualification');
    my $qualification_name = $c->crp->trimmed_param('qualification');
    $validation->error('qualification', ['invalid_column_MinLen']) unless length $qualification_name >= 10;
    $validation->error('qualification', ['invalid_column_MaxLen']) unless length $qualification_name <= 100;
    my $code;
    if( ! $id) {
        $validation->required('code');
        $code = $c->crp->trimmed_param('code');
        $validation->error('code', ['duplicate_code']) if $c->crp->model('Qualification')->find({code => $code});
    }
    return $c->page('edit_qualification') if $validation->has_error;

    my $qualification = ($id
        ? $c->crp->model('Qualification')->find($id)
        : $c->crp->model('Qualification')->new_result({})
    ) || return $c->welcome;

    $qualification->abbreviation($abbreviation);
    $qualification->qualification($qualification_name);
    $qualification->code($code) unless $id;
    $qualification->olccodes($c->crp->trimmed_param('olccodes'));
    $qualification->update_or_insert;

    return $c->redirect_to($c->url_for('crp.admin_default'));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub delete_qualification {
    my $c = shift;

    my $id = $c->param('id');
    my $qualification = $c->_load_deletable_qualification($id) || return $c->welcome;
    $c->stash('crp_session')->variable('id', $id);
    $c->stash('qualification', $qualification);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub do_delete_qualification {
    my $c = shift;

    my $id = $c->stash('crp_session')->remove_variable('id');
    my $qualification = $c->_load_deletable_qualification($id) || return $c->welcome;
    $c->flash(msg => 'qualification_delete');
    $qualification->delete;
    return $c->redirect_to($c->url_for('crp.admin_default'));
}

sub _load_deletable_qualification {
    my $c = shift;
    my($id) = @_;

    my $qualification   = $c->crp->model('Qualification')->find($id) || return $c->welcome;
    return unless $qualification
        && $qualification->instructor_qualifications->get_passed_set->count == 0
        && $qualification->instructor_qualifications->get_in_training_set->count == 0;
    return $qualification;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PremiumContent;
sub premium_content {
    my $c = shift;

    $c->stash(paths => CRP::Util::PremiumContent::paths($c));
    $c->render(template => 'admin/premium_content');
}


sub premium_auth {
    my $c = shift;

    if($c->req->method eq 'POST') {
        my $email = $c->_get_and_validate_email_param();
        my $name = $c->crp->trimmed_param('name');
        my $dir = $c->crp->trimmed_param('dir');
        my $validation = $c->validation;
        $validation->required('name')->like(qr{\S+});
        $validation->required('dir');
        if( ! $validation->has_error && CRP::Util::PremiumContent::id_from_email_and_dir($c, $email, $dir)) {
            $validation->error(email => ['duplicate_email_premium']);
        }
        return $c->premium_content if $validation->has_error;

        CRP::Util::PremiumContent::create_authorisation($c, $email, $dir, $name);
        $c->flash(msg => 'premium_create');
        return $c->redirect_to($c->url_for('crp.admin_premium'));
    }
    return $c->premium_content;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
#use CRP::Util::BlogContent;
sub blog_content {
    my $c = shift;
}

sub create_blog {
    my $c = shift;

    $c->render(template => 'admin/blog_article');
}




1;

