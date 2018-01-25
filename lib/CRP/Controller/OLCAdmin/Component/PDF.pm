package CRP::Controller::OLCAdmin::Component::PDF;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use Try::Tiny;

use CRP::Util::Misc;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $dir = $c->app->home->rel_file('pdfs/olc/uploaded')->to_string;
    my $extra_data = {
        files => CRP::Util::Misc::get_file_list($dir, qr{^/([^.].*\.pdf)$}i),
    };
    $c->_display_component_editor('o_l_c_admin/component/editor/pdf', $extra_data);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub save {
    my $c = shift;

    my $pdf_file_name = $c->_process_uploaded_pdf // $c->crp->trimmed_param('pdf_file');
    $c->validation->error(upload => ['file_required']) unless $pdf_file_name;
    return $c->edit if $c->validation->has_error;
    die "Couldn't process PDF" unless $pdf_file_name;

    my $component = $c->_component;
    $component->data_version(1);
    $component->name($c->crp->trimmed_param('name'));
    $component->data({
        file    => $pdf_file_name,
        title   => $c->crp->trimmed_param('title'),
    });
    $component->create_or_update;
    $c->_return_to_page_editor;
}

sub _process_uploaded_pdf {
    my $c = shift;

    my $validation_error;
    my $actual_file_name;

    my $pdf = $c->req->upload('upload');

    if($pdf->size > ($c->config->{olc}->{max_pdf_file_size} || 10_000_000)) {
        $validation_error = 'file_too_large';
    }
    elsif($pdf->size < 1) {
        return;
    }
    else {
        use File::Temp;
        my($fh, $temp_file) = tmpnam();
        close $fh;

        my $error;
        try {
            $pdf->move_to($temp_file);
            use File::Copy;
            $actual_file_name = $c->_get_unique_uploaded_pdf_file_name($c->req->upload('upload')->filename);
            move $temp_file, $actual_file_name or die "Failed to move '$temp_file' to '$actual_file_name': $!";
        }
        catch {
            $error = $_;
        };
        unlink $temp_file;
        die $error if $error;

        $validation_error = $c->_validate_pdf($actual_file_name);
        unlink $actual_file_name if $validation_error;
    }

    if($validation_error) {
        $c->validation->error(upload => [$validation_error]);
        return;
    }

    $actual_file_name =~ s/^.*\///;
    return $actual_file_name;
}

sub _validate_pdf {
    my $c = shift;
    my($pathname) = @_;

    my $validation_error;
    try {
        my $pdf_doc = PDF::API2->open($pathname);
        die "PDF version too high" unless $pdf_doc->version <= 1.4;
    }
    catch {
        $validation_error = 'invalid_pdf';
    };

    return $validation_error;
}

sub _get_unique_uploaded_pdf_file_name {
    my $c = shift;
    my($proposed_name) = @_;

    my $base_dir = $c->app->home->rel_file('pdfs/olc/uploaded')->to_string;
    return CRP::Util::Misc::get_unique_file_name($base_dir, $proposed_name);
}

1;

