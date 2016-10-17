package CRP;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::RenderFile;
use DBIx::Connector;

use CRP::Plugin::CSRFProtect;
use CRP::Helper::Main;
use CRP::Plugin::ETag;
use CRP::Model::Schema;
use CRP::Util::Session;

# This method will run once at server start
sub startup {
    my $self = shift;

    warn __PACKAGE__ . " Starting\n" if $self->mode eq 'development';

    my $config = $self->plugin('Config');
    $self->plugin('CRP::Plugin::CSRFProtect', on_error => \&_csrf_error_handler);
    $self->plugin('CRP::Helper::Main');
    $self->plugin('CRP::Plugin::ETag');
    $self->plugin('RenderFile');
    $self->plugin(mail => $config->{mail});
    $self->secrets([$config->{secret}]);
    $self->sessions->cookie_name($config->{session}->{cookie_name});

    push @{$self->app->commands->namespaces}, 'CRP::Command';

    $self->app->types->type(csv => 'text/csv;charset=UTF-8');

    if($config->{recaptcha}->{secretkey}) {
        $self->plugin('ReCAPTCHAv2', {
            sitekey       => $config->{recaptcha}->{sitekey},
            secret        => $config->{recaptcha}->{secretkey},
        });
    }

    # Router
    my $r = $self->routes;

    my $sq_app = $self->app->home->rel_file('../sq/script/sq');
    if(-e $sq_app) {
        $sq_app = Mojo::Server->new->load_app($sq_app) if -e $sq_app;
        $r->get('/')->over(headers => {Host => qr/(^|\.)susanquayle\.co\./})->detour(app => $sq_app);
    }

    $r->get('/')->to('main#welcome');
    $r->any('/update_registration')->to('main#update_registration');
    $r->any('/main/contact')->to('main#contact');
    $r->any('/main/register_interest')->to('main#register_interest')->name('crp.register_interest');
    $r->any('/main/resend_confirmation')->to('main#resend_confirmation');
    $r->any('/login')->to('logged_in#login')->name('crp.login');
    $r->any('/instructors')->to('main#instructors')->name('crp.instructors');
    $r->any('/instructor_booking_form')->to('main#instructor_booking_form')->name('crp.instructor_booking_form');
    $r->any('/cookies_ok')->to('main#cookies_ok')->name('crp.accept_cookies');
    $r->any('/logout')->to('logged_in#logout')->name('crp.logout');
    $r->get('/page/*page')->to('main#page')->name('crp.page');
    $r->any('/otp')->to('logged_in#otp');
    $r->get('/otp/*otp')->to('logged_in#otp');
    $r->get('/tutor_list')->to('main#tutor_list')->name('crp.tutor_list');
    $r->get('/fresh/:cachebuster/*path')->to('main#fresh')->name('crp.fresh');
    $r->any('main/instructor_search')->to('main#instructor_search')->name('crp.instructor_search');
    $r->any('main/location_search')->to('main#location_search')->name('crp.location_search');
    $r->post('main/instructor_booking')->to('main#instructor_booking')->name('crp.instructor_booking');
    $r->any('main/instructor_poster')->to('main#instructor_poster')->name('crp.instructor_poster');

    my $logged_in = $r->under('/instructor')->to('logged_in#authenticate');
    $logged_in->get('/')->to('members#welcome')->name('crp.logged_in_default');
    $logged_in->any('/set_password')->to('logged_in#set_password')->name('crp.set_password');
    $logged_in->any('/profile')->to('members#profile')->name('crp.members.profile');
    $logged_in->any('page/*page')->to('members#page')->name('crp.members.page');
    $logged_in->any('help/:faq_id')->to('members#faqs')->name('crp.members.faqs');
    $logged_in->any('help')->to('members#faqs')->name('crp.members.faqs');
    $logged_in->any('get_pdf/*pdf')->to('members#get_pdf')->name('crp.members.get_pdf');
    $logged_in->any('find_enquiries')->to('members#find_enquiries')->name('crp.members.find_enquiries');
    $logged_in->any('courses')->to('members#courses')->name('crp.members.courses');
    $logged_in->any('course')->to('members#course')->name('crp.members.course');
    $logged_in->any('cancel_course')->to('members#cancel_course')->name('crp.members.cancel_course');
    $logged_in->any('do_cancel_course')->to('members#do_cancel_course')->name('crp.members.do_cancel_course');
    $logged_in->any('delete_course')->to('members#delete_course')->name('crp.members.delete_course');
    $logged_in->any('do_delete_course')->to('members#do_delete_course')->name('crp.members.do_delete_course');
    $logged_in->any('publish_course')->to('members#publish_course')->name('crp.members.publish_course');
    $logged_in->any('do_publish_course')->to('members#do_publish_course')->name('crp.members.do_publish_course');
    $logged_in->any('course_docs')->to('members#course_docs')->name('crp.members.course_docs');
    $logged_in->any('pdf_image/*name')->to('members#pdf_image')->name('crp.members.pdf_image');
    $logged_in->any('course_pdf/:course_id/*name')->to('members#course_pdf')->name('crp.members.course_pdf');

    my $trainers = $logged_in->under('/trainer')->to('trainers#authenticate');
    $trainers->any('courses')->to('trainers#courses')->name('crp.trainers.courses');
    $trainers->any('course')->to('trainers#course')->name('crp.trainers.course');
    $trainers->any('cancel_course')->to('trainers#cancel_course')->name('crp.trainers.cancel_course');
    $trainers->any('do_cancel_course')->to('trainers#do_cancel_course')->name('crp.trainers.do_cancel_course');
    $trainers->any('delete_course')->to('trainers#delete_course')->name('crp.trainers.delete_course');
    $trainers->any('do_delete_course')->to('trainers#do_delete_course')->name('crp.trainers.do_delete_course');
    $trainers->any('publish_course')->to('trainers#publish_course')->name('crp.trainers.publish_course');
    $trainers->any('do_publish_course')->to('trainers#do_publish_course')->name('crp.trainers.do_publish_course');
    $trainers->any('course_docs')->to('trainers#course_docs')->name('crp.trainers.course_docs');
    $trainers->any('course_pdf/:course_id/*name')->to('trainers#course_pdf')->name('crp.trainers.course_pdf');

    my $admin = $logged_in->under('/admin')->to('admin#authenticate');
    $admin->get('/')->to('admin#welcome')->name('crp.admin_default');
    $admin->any('/find_account')->to('admin#find_account')->name('crp.admin.find_account');
    $admin->any('/show_account')->to('admin#show_account')->name('crp.admin.show_account');
    $admin->any('/certificate')->to('admin#certificate')->name('crp.admin.certificate');
    $admin->any('/admin_login')->to('logged_in#admin_login')->name('crp.admin.login');
    $admin->any('/create_account')->to('admin#create_account')->name('crp.admin.create_account');
    $admin->any('/parent_courses')->to('admin#list_parent_courses')->name('crp.admin.parent_courses');
    $admin->any('/instructor_courses')->to('admin#list_instructor_courses')->name('crp.admin.instructor_courses');
    $admin->post('/change_demo')->to('admin#change_demo')->name('crp.admin.change_demo');
    $admin->post('/change_email')->to('admin#change_email')->name('crp.admin.change_email');
    $admin->post('/add_instructor_qualification')->to('admin#add_instructor_qualification')->name('crp.admin.add_instructor_qualification');
    $admin->post('/delete_instructor_qualification')->to('admin#delete_instructor_qualification')->name('crp.admin.delete_instructor_qualification');
    $admin->post('/set_pass_date')->to('admin#set_pass_date')->name('crp.admin.set_pass_date');
    $admin->any('/edit_qualification')->to('admin#edit_qualification')->name('crp.admin.edit_qualification');
    $admin->any('/add_qualification')->to('admin#add_qualification')->name('crp.admin.add_qualification');
    $admin->post('/save_qualification')->to('admin#save_qualification')->name('crp.admin.save_qualification');
    $admin->any('delete_qualification')->to('admin#delete_qualification')->name('crp.admin.delete_qualification');
    $admin->any('do_delete_qualification')->to('admin#do_delete_qualification')->name('crp.admin.do_delete_qualification');
    $admin->any('premium_content')->to('admin#premium_content')->name('crp.admin_premium');

    my $member_site = $r->under('/me/:slug')->to('member_site#identify');
    $member_site->any('/')->to('member_site#welcome')->name('crp.membersite.home');
    $member_site->any('/certificate')->to('member_site#certificate')->name('crp.membersite.certificate');
    $member_site->any('/mental_capacity_form')->to('member_site#mencap_form')->name('crp.membersite.mencap_form');
    $member_site->any('/course/:course')->to('member_site#course')->name('crp.membersite.course');
    $member_site->any('/course/:course/booking_form')->to('member_site#booking_form')->name('crp.membersite.booking_form');
    $member_site->any('/course/:course/book_online')->to('member_site#book_online')->name('crp.membersite.book_online');
    $member_site->post('/course/:course/send_booking')->to('member_site#send_booking')->name('crp.membersite.send_booking');

    my $tests = $r->under('/test')->to('test#authenticate');
    $tests->get('/')->to('test#welcome');
    $tests->get('/template/*template')->to('test#template');
    $tests->get('/list_pdfs')->to('test#list_pdfs');
    $tests->get('/pdf/*pdf')->to('test#pdf');
    $tests->get('/email/*email')->to('test#email');

    $self->app->hook(before_dispatch => \&_before_dispatch);
    $self->app->hook(after_dispatch => \&_after_dispatch);
}

sub _before_dispatch {
    my $c = shift;

    $c->stash(cookies_accepted => 1) if $c->cookie($c->config->{cookie_check_cookie_name});
    if($c->cookie($c->config->{session}->{cookie_name})) {
        $c->stash(crp_session => CRP::Util::Session->new(mojo => $c));
        $c->stash(logged_in => $c->crp->logged_in_instructor_id);
        $c->stash(is_demo => $c->crp->load_profile->login->is_demo) if $c->stash('logged_in');
    }

    if($c->app->mode eq 'production') {
        my $url  = $c->req->url->to_abs;
        my $path = $c->req->url->path;

        return if $url->host =~ /^www\./;

        $url->host('www.' . $url->host);
        $c->res->code(301);
        $c->redirect_to($url->to_string);
    }
}

sub _after_dispatch {
    my $c = shift;

    $c->stash('crp_session')->write() if $c->stash('crp_session');
}

sub _csrf_error_handler {
    my $c = shift;

    $c->render(template => 'csrf_violation', status => 403);
}

1;

