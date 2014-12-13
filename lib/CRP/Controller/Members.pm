package CRP::Controller::Members;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;

use Try::Tiny;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    my $profile = $c->_load_profile;
    $c->stash(incomplete_profile => ! $profile->is_complete);
    $c->render;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');
    $c->stash('page', $page);

    $c->render(template => "members/pages/$page");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub profile {
    my $c = shift;

    my $profile = $c->_load_profile;
    $c->stash(site_profile => $profile);

    if($c->req->method eq 'POST') {
        my $validation = $c->validation;

        $c->_process_uploaded_photo;
        foreach my $field (qw(name address postcode telephone mobile blurb)) {
            eval { $profile->$field($c->param($field)); };
            my $error = $@;
            if($error =~ m{^CRP::Util::Types::(.+?) }) {
                $validation->error($field => ["invalid_column_$1"]);
            }
            else {
                die $error if $error;
            }
        }
        if($validation->has_error) {
            $c->stash(msg => 'fix_errors');
        }
        else {
            $profile->update;
            $c->stash(msg => 'profile_update');
        }
    }

    $c->render;
}

use CRP::Util::Graphics;
sub _process_uploaded_photo {
    my $c = shift;

    my $photo = $c->req->upload('photo');
    return unless $photo->size;

    use File::Temp;
    my($fh, $filename) = tmpnam();
    close $fh;

    my $error;
    try {
        $photo->move_to($filename);
        if(CRP::Util::Graphics::resize(
                $filename,
                $c->config->{instructor_photo}->{width},
                $c->config->{instructor_photo}->{height},
            )) {
        }
        else {
            $c->validation->error(photo => ['invalid_image_file']);
        }
    }
    catch {
        $error = $_;
    };
    unlink $filename;
    die $error if $error;
}

sub _load_profile {
    my $c = shift;

    my $instructor_id = $c->stash('crp_session')->variable('instructor_id');
    my $profile = $c->crp->model('Profile')->find_or_create({instructor_id => $instructor_id});
    $c->stash('profile_record', $profile);
    return $profile;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDF;
sub get_pdf {
    my $c = shift;

    my $pdf = shift // $c->stash('pdf');
    $pdf = $c->app->home->rel_file("pdfs/members/$pdf.pdf");
    return $c->reply->not_found unless -r $pdf;

    my $profile = $c->_load_profile;
    my $url = $c->url_for('crp.membersite.home', slug => $profile->web_page_slug)->to_abs;
    $url =~ s{.+?://}{};
    my $pdf_doc = CRP::Util::PDF::fill_template(
        $pdf,
        {
            profile => $profile,
            url     => $url,
            email   => $c->stash('crp_session')->variable('email'),
        }
    );

    $c->render_file(
        data                => $pdf_doc,
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub find_enquiries {
    my $c = shift;

    $c->_load_profile;
    my $latitude = $c->param('latitude') // '';
    my $longitude = $c->param('longitude') // '';
    if($latitude ne '' && $longitude ne '') {
        my $enquiries_list = [
            $c->crp->model('Enquiry')->search_near_location(
                $latitude,
                $longitude,
                $c->config->{'enquiry_search_distance'},
                { notify_tutors => 1 },
            )
        ];
        $c->stash(enquiries_list => $enquiries_list);
    }
    $c->render(template => 'members/find_enquiries');
}

1;

