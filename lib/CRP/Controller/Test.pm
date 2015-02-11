package CRP::Controller::Test;
use Mojo::Base 'Mojolicious::Controller';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $self = shift;

    return 1 if $self->app->mode eq 'development';
    $self->reply->not_found;
    return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    $c->render;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub template {
    my $c = shift;

    my $template = shift || $c->stash('template');
    $c->render(template => $template);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub list_pdfs {
    my $c = shift;

    my @files;
    use File::Find;
    my $base_dir = $c->app->home->rel_file('pdfs');
    find({ wanted => sub {
                s{^$base_dir}{};
                push @files, $_ if m{^[^.].*\.pdf$};
            },
            no_chdir => 1,
        },
        $base_dir
    );
    $c->stash(pdflist_members => \@files);
    return $c->template('test/list_pdfs');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDFMarkUp;
sub pdf {
    my $c = shift;

    my $pdf = shift // $c->stash('pdf');
    $pdf = $c->app->home->rel_file("pdfs/$pdf");
    return $c->reply->not_found unless -r $pdf;

    my $pdf_doc = CRP::Util::PDFMarkUp->new(file_path => $pdf, test_mode => 1);
    $c->render_file(
        data                => $pdf_doc->fill_template,
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub email {
    my $c = shift;

    my $email = shift // $c->stash('email');
    my $email_id;
    if($email eq 'main/email/otp') {
        $email_id = 'Temporary password';
        my $identifier = "IDENTIFIER";
        my $otp = "RANDOM-PASSWORD";
        my $info = {
            identifier          => "$identifier/$otp",
            otp_page            => $c->url_for("/otp/$identifier/$otp")->to_abs(),
            general_otp_page    => $c->url_for('/otp')->to_abs(),
            hours               => $c->app->config->{login}->{otp_lifetime},
        };
        $c->stash(info => $info);
    }
    elsif($email eq 'members/email/profile_update') {
        $email_id = 'Admin notification of Instructor update';
        my $info = {
            changes => {
                name        => 'NEW_NAME',
                address     => 'NEW_ADDRESS',
                telephone   => 'NEW_TELEPHONE',
                location    => 'NEW_LOCATION',
            },
            id => 'INSTRUCTOR_ID',
            url => $c->url_for('crp.membersite.home', slug => 'INSTRUCTOR_SLUG')->to_abs,
        };
        $c->stash(info => $info);
    }
    elsif($email eq 'main/email/contact_form') {
        $email_id = 'Contact form';
        $c->stash(info => {message => 'Message text entered on the form.'});
    }
    elsif($email eq 'main/email/enquiry_confirmation') {
        $email_id = 'Enquiry email-address confirmation';
        my $identifier = 'UNIQUE_IDENTIFIER';
        my $info = {
            identifier              => $identifier,
            confirm_page            => $c->url_for('/update_registration')->query(id => $identifier)->to_abs(),
            general_confirm_page    => $c->url_for('/update_registration')->to_abs(),
            location                => 'LOCATION',
            notify_new_courses      => 1,
            notify_tutors           => 1,
            send_newsletter         => 1,
            name                    => 'ENQUIRER_NAME',
        };
        $c->stash(info => $info);
    }
    elsif($email eq 'members/email/course_published_to_enquirer') {
        $email_id = 'Enquirer email re new course';
        my $identifier = 'UNIQUE_IDENTIFIER';
        my $info = {
            confirm_page    => $c->url_for('/update_registration')->query(id => $identifier)->to_abs(),
            name            => 'ENQUIRER_NAME',
            url             => $c->url_for('crp.membersite.course', slug => 'INSTRUCTOR_SLUG', course => 'COURSE_ID')->to_abs,
        };
        $c->stash(info => $info);
    }
    $c->stash(email_id => $email_id);
    $c->stash(email_path => $email);
    $c->stash(email_html => $c->render_to_string($email, format => 'mail'));
}

1;

