package CRP::Controller::OLCAdmin::Component::PDF;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use Try::Tiny;

use CRP::Model::OLC::ResourceStore;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $resource_store = CRP::Model::OLC::ResourceStore->new(c => $c);
    my $resources = $resource_store->get_resource_list('file/pdf');
    my $extra_data = {
        files         => [ map { $_->name } @$resources ],
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
            my $resource_store = CRP::Model::OLC::ResourceStore->new(c => $c);
            $actual_file_name = $resource_store->move_file_to_store($temp_file, $c->req->upload('upload')->filename, 'file/pdf');
            use File::Copy;
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

1;

