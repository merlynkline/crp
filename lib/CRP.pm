package CRP;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::RenderFile;
use DBIx::Connector;

use CRP::Plugin::CSRFProtect;
use CRP::Helper::Main;
use CRP::Helper::Markdown;
use CRP::Plugin::ETag;
use CRP::Model::Schema;
use CRP::Util::Session;

# This method will run once at server start
sub startup {
    my $self = shift;

    warn __PACKAGE__ . " Starting\n" if $self->mode eq 'development';

    my $config = $self->plugin('Config');
    $config = $self->plugin('Config', {file => 'c_r_p.conf.private'});
    $self->plugin('CRP::Plugin::CSRFProtect', on_error => \&_csrf_error_handler);
    $self->plugin('CRP::Helper::Main');
    $self->plugin('CRP::Helper::Markdown');
    $self->plugin('CRP::Plugin::ETag');
    $self->plugin('RenderFile');
    $self->plugin('TemplateToolkit', {template => {
                PRE_CHOMP   => 1,
                POST_CHOMP  => 1,
                COMPILE_DIR => '/tmp/mojo_tcrp_ttc',
            }},
    );
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

    $self->app->max_request_size(512 * 1024 * 1024);

    unshift @{$self->renderer->paths}, $config->{template_dir} if $config->{template_dir};

    # Router
    my $r = $self->routes;

    my $sq_app = $self->app->home->rel_file('../sq/script/sq')->to_string;
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
    $r->any('professional/:slug')->to('main#professional_page')->name('crp.pro_page');
    $r->any('professional/:slug/pdf/*pdf')->to('main#professional_pdf')->name('crp.pro_pdf');
    $r->any('professional/:slug/pdf_thumb/*name')->to('main#professional_pdf_image')->name('crp.pro_pdf_img');
    $r->any('professional/:signature/verify')->to('main#professional_verify_signature')->name('crp.pro_verify');

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
    $logged_in->any('fbprofilepic')->to('members#fb_profile_pic')->name('crp.members.fbprofilepic');

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
    $trainers->any('attendees')->to('trainers#attendees')->name('crp.trainers.attendees');
    $trainers->any('attendee')->to('trainers#attendee')->name('crp.trainers.attendee');
    $trainers->any('attendee_email')->to('trainers#attendee_email')->name('crp.trainers.attendee_email');
    $trainers->any('send_attendee_email')->to('trainers#send_attendee_email')->name('crp.trainers.send_attendee_email');
    $trainers->any('attendee_certificate')->to('trainers#attendee_certificate')->name('crp.trainers.attendee_certificate');
    $trainers->any('attendee_delete')->to('trainers#attendee_delete')->name('crp.trainers.attendee_delete');
    $trainers->any('do_attendee_delete')->to('trainers#do_attendee_delete')->name('crp.trainers.do_attendee_delete');

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
    $admin->any('premium_auth')->to('admin#premium_auth')->name('crp.admin.create_premium');
    $admin->any('blog_content')->to('admin#blog_content')->name('crp.admin_blog');
    $admin->any('blog_article')->to('admin#blog_article')->name('crp.admin.create_blog');

    my $olc_admin = $admin->under('/olc');
    $olc_admin->get('/')->to('o_l_c_admin#welcome')->name('crp.olcadmin.default');
    $olc_admin->get('/remote')->to('o_l_c_admin#remote')->name('crp.olcadmin.remote');
    $olc_admin->get('/remoteupdate')->to('o_l_c_admin#remote_update')->name('crp.olcadmin.remoteupdate');
    $olc_admin->any('/assignment')->to('o_l_c_admin#assignment')->name('crp.olcadmin.assignment');
    my $olc_admin_course = $olc_admin->under('/course');
    $olc_admin_course->any('/')->to('o_l_c_admin-course#edit')->name('crp.olcadmin.course.edit');
    $olc_admin_course->post('save')->to('o_l_c_admin-course#save')->name('crp.olcadmin.course.save');
    $olc_admin_course->any('pickmodules')->to('o_l_c_admin-course#pickmodules')->name('crp.olcadmin.course.pickmodules');
    $olc_admin_course->any('addmodules')->to('o_l_c_admin-course#addmodules')->name('crp.olcadmin.course.addmodules');
    $olc_admin_course->post('moduleup')->to('o_l_c_admin-course#moduleup')->name('crp.olcadmin.course.module.moveup');
    $olc_admin_course->post('moduledown')->to('o_l_c_admin-course#moduledown')->name('crp.olcadmin.course.module.movedown');
    $olc_admin_course->post('moduledelete')->to('o_l_c_admin-course#moduledelete')->name('crp.olcadmin.course.module.delete');
    my $olc_admin_module = $olc_admin->under('/module');
    $olc_admin_module->any('/')->to('o_l_c_admin-module#edit')->name('crp.olcadmin.module.edit');
    $olc_admin_module->post('save')->to('o_l_c_admin-module#save')->name('crp.olcadmin.module.save');
    $olc_admin_module->any('pickpages')->to('o_l_c_admin-module#pickpages')->name('crp.olcadmin.module.pickpages');
    $olc_admin_module->any('addpages')->to('o_l_c_admin-module#addpages')->name('crp.olcadmin.module.addpages');
    $olc_admin_module->post('pageup')->to('o_l_c_admin-module#pageup')->name('crp.olcadmin.module.page.moveup');
    $olc_admin_module->post('pagedown')->to('o_l_c_admin-module#pagedown')->name('crp.olcadmin.module.page.movedown');
    $olc_admin_module->post('pagedelete')->to('o_l_c_admin-module#pagedelete')->name('crp.olcadmin.module.page.delete');
    my $olc_admin_page = $olc_admin->under('/page');
    $olc_admin_page->any('/')->to('o_l_c_admin-page#edit')->name('crp.olcadmin.page.edit');
    $olc_admin_page->post('save')->to('o_l_c_admin-page#save')->name('crp.olcadmin.page.save');
    $olc_admin_page->any('addcomponent')->to('o_l_c_admin-page#addcomponent')->name('crp.olcadmin.page.component.add');
    $olc_admin_page->post('componentup')->to('o_l_c_admin-page#componentup')->name('crp.olcadmin.page.component.moveup');
    $olc_admin_page->post('componentdown')->to('o_l_c_admin-page#componentdown')->name('crp.olcadmin.page.component.movedown');
    $olc_admin_page->post('componentdelete')->to('o_l_c_admin-page#componentdelete')->name('crp.olcadmin.page.component.delete');
    my $olc_admin_component = $olc_admin->under('/component');
    $olc_admin_component->any('/edit')->to('o_l_c_admin-component#edit')->name('crp.olcadmin.component.edit');
    $olc_admin_component->any('/heading/edit')->to('o_l_c_admin-component-heading#edit')->name('crp.olcadmin.component.heading.edit');
    $olc_admin_component->post('/heading/save')->to('o_l_c_admin-component-heading#save')->name('crp.olcadmin.component.heading.save');
    $olc_admin_component->any('/paragraph/edit')->to('o_l_c_admin-component-paragraph#edit')->name('crp.olcadmin.component.paragraph.edit');
    $olc_admin_component->post('/paragraph/save')->to('o_l_c_admin-component-paragraph#save')->name('crp.olcadmin.component.paragraph.save');
    $olc_admin_component->any('/markdown/edit')->to('o_l_c_admin-component-markdown#edit')->name('crp.olcadmin.component.markdown.edit');
    $olc_admin_component->post('/markdown/save')->to('o_l_c_admin-component-markdown#save')->name('crp.olcadmin.component.markdown.save');
    $olc_admin_component->any('/courseidx/edit')->to('o_l_c_admin-component-course_i_d_x#edit')->name('crp.olcadmin.component.courseidx.edit');
    $olc_admin_component->post('/courseidx/save')->to('o_l_c_admin-component-course_i_d_x#save')->name('crp.olcadmin.component.courseidx.save');
    $olc_admin_component->any('/moduleidx/edit')->to('o_l_c_admin-component-module_i_d_x#edit')->name('crp.olcadmin.component.moduleidx.edit');
    $olc_admin_component->post('/moduleidx/save')->to('o_l_c_admin-component-module_i_d_x#save')->name('crp.olcadmin.component.moduleidx.save');
    $olc_admin_component->any('/image/edit')->to('o_l_c_admin-component-image#edit')->name('crp.olcadmin.component.image.edit');
    $olc_admin_component->post('/image/save')->to('o_l_c_admin-component-image#save')->name('crp.olcadmin.component.image.save');
    $olc_admin_component->any('/singleopt/edit')->to('o_l_c_admin-component-single_option#edit')->name('crp.olcadmin.component.singleopt.edit');
    $olc_admin_component->post('/singleopt/save')->to('o_l_c_admin-component-single_option#save')->name('crp.olcadmin.component.singleopt.save');
    $olc_admin_component->any('/multipleopt/edit')->to('o_l_c_admin-component-multiple_option#edit')->name('crp.olcadmin.component.multipleopt.edit');
    $olc_admin_component->post('/multipleopt/save')->to('o_l_c_admin-component-multiple_option#save')->name('crp.olcadmin.component.multipleopt.save');
    $olc_admin_component->any('/tutormarked/edit')->to('o_l_c_admin-component-tutor_marked#edit')->name('crp.olcadmin.component.tutormarked.edit');
    $olc_admin_component->post('/tutormarked/save')->to('o_l_c_admin-component-tutor_marked#save')->name('crp.olcadmin.component.tutormarked.save');
    $olc_admin_component->any('/video/edit')->to('o_l_c_admin-component-video#edit')->name('crp.olcadmin.component.video.edit');
    $olc_admin_component->post('/video/save')->to('o_l_c_admin-component-video#save')->name('crp.olcadmin.component.video.save');
    $olc_admin_component->any('/pdf/edit')->to('o_l_c_admin-component-p_d_f#edit')->name('crp.olcadmin.component.pdf.edit');
    $olc_admin_component->post('/pdf/save')->to('o_l_c_admin-component-p_d_f#save')->name('crp.olcadmin.component.pdf.save');

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

    $r->post($self->config->{premium}->{root} . '/:dir/_control/link_request')->to('premium#link_request')->name('crp.premium.linkrequest');
    $r->any($self->config->{premium}->{root} . '/:dir/_control/link_request_sent')->to('premium#link_request_sent')->name('crp.premium.linkrequestsent');
    $r->any($self->config->{premium}->{root} . '/:dir/*subpath')->to('premium#content')->name('crp.premium.page');
    $r->any($self->config->{premium}->{root} . '/:dir')->to('premium#content');

    my $api = $r->under('/api')->to('a_p_i#authenticate');
    $api->any('/courses')->to('a_p_i#courses');
    $api->any('/course/state')->to('a_p_i#course_state');
    $api->any('/object_definition')->to('a_p_i#object_definition');

    my $olc = $r->under('/olc/:slug/:course_id')->to('o_l_c#authenticate');
    $olc->get('/show/:module_id/:page_id')->to('o_l_c#show_page')->name('crp.olc.showpage');
    $olc->get('/show/:module_id')->to('o_l_c#show_page')->name('crp.olc.showmodule');
    $olc->get('/show')->to('o_l_c#show_page')->name('crp.olc.showcourse');
    $olc->post('/check/:module_id/:page_id')->to('o_l_c#check_page')->name('crp.olc.checkpage');
    $olc->post('/check/:module_id')->to('o_l_c#check_page')->name('crp.olc.checkmodule');
    $olc->any('/logout')->to('o_l_c#logout')->name('crp.olc.logout');
    $olc->any('/completed')->to('o_l_c#completed')->name('crp.olc.completed');
    $olc->any('/certificate')->to('o_l_c#pdf_certificate')->name('crp.olc.pdf_certificate');
    $olc->any('/pdf/:file')->to('o_l_c#pdf')->name('crp.olc.pdf');
    $olc->any('/video/*file')->to('o_l_c#video')->name('crp.olc.video');
    $r->any('/olc-certificate/:signature')->to('o_l_c#public_certificate')->name('crp.olc.public_certificate');


    $self->app->hook(before_dispatch => \&_before_dispatch);
    $self->app->hook(after_dispatch => \&_after_dispatch);
    $self->app->hook(after_static => \&_after_static);
    $self->app->hook(after_render => \&_after_render);
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

        return if $url->host eq 'www.kidsreflex.co.uk' && $url->scheme eq 'https';
        return if _is_good_url($c, $url);

        $url = _make_good_url($c, $url);
        $url->host('www.kidsreflex.co.uk');
        $url->scheme('https');

        $c->res->code(301);
        $c->redirect_to($url->to_string);
    }
}

sub _is_good_url {
    my($c) = shift;
    my($url) = @_;

    my($host, $domain) = split /\./, $url->host, 2;
    $domain = lc($domain || '');
    $host   = lc($host || '');
    return lc $host eq 'www'
        && exists $c->config->{domain_names}->{$domain}
        && $url->scheme eq _scheme_from_type($c->config->{domain_names}->{$domain});
}

sub _scheme_from_type {
    my($type) = @_;

    return $type eq 'ssl' ? 'https' : 'http';
}

sub _make_good_url {
    my($c) = shift;
    my($url) = @_;

    my($host, $domain) = split /\./, $url->host, 2;
    $domain = lc($domain || '');
    $host   = lc($host || '');

    unless($host eq 'www') {
        $domain = "$host.$domain";
        $host = 'www';
    }

    $domain = 'kidsreflex.co.uk' unless exists $c->config->{domain_names}->{$domain};

    $url->host("$host.$domain");
    $url->scheme(_scheme_from_type($c->config->{domain_names}->{$domain}));
    $url->port(undef);
    return $url;
}

sub _after_dispatch {
    my $c = shift;

    $c->stash('crp_session')->write() if $c->stash('crp_session');
}

sub _csrf_error_handler {
    my $c = shift;

    $c->render(template => 'csrf_violation', status => 403);
}

use IO::Compress::Gzip 'gzip';
sub _after_render {
    my ($c, $output, $format) = @_;

    return unless ($c->req->headers->accept_encoding // '') =~ /gzip/i;

    $c->res->headers->append(Vary => 'Accept-Encoding');
    $c->res->headers->content_encoding('gzip');
    gzip $output, \my $compressed;
    $$output = $compressed;
}

sub _after_static {
    my $c = shift;

    return unless $c->res->code;
    my $age = 60 * 60 * 4;
    $age = 0 if $c->app->mode eq 'development' && $c->req->url->path->parts->[-1] =~ /\.css$/;

    $c->res->headers->cache_control("max-age=$age, must-revalidate");
    $c->res->headers->header("Cache-Control" => "public");
    $c->res->headers->header(Expires => Mojo::Date->new(time + $age));
}

1;

