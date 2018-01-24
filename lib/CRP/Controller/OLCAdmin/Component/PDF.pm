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

    my $pdf = $c->req->upload('upload');
    return unless $pdf->size;

    if($pdf->size > ($c->config->{olc}->{max_pdf_file_size} || 10_000_000)) {
        $c->validation->error(upload => ['file_too_large']);
        return;
    }

    use File::Temp;
    my($fh, $temp_file) = tmpnam();
    close $fh;

    my $actual_file_name;
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

    $actual_file_name =~ s/^.*\///;
    return $actual_file_name;
}

sub _get_unique_uploaded_pdf_file_name {
    my $c = shift;
    my($proposed_name) = @_;

    my $base_dir = $c->app->home->rel_file('pdfs/olc/uploaded')->to_string;
    return CRP::Util::Misc::get_unique_file_name($base_dir, $proposed_name);
}

1;

