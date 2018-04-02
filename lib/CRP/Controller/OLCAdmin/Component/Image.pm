package CRP::Controller::OLCAdmin::Component::Image;

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
    my $resources = $resource_store->get_resource_list('file/image');
    my $extra_data = {
        files         => [ map { $_->name } @$resources ],
        file_base_url => $resource_store->url_base('file/image'),
    };
    $c->_display_component_editor('o_l_c_admin/component/editor/image', $extra_data);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub save {
    my $c = shift;

    my $image_file_name = $c->_process_uploaded_image // $c->crp->trimmed_param('image_file');
    my $component = $c->_component;
    $component->data_version(1);
    $component->name($c->crp->trimmed_param('name'));
    $component->data({
        file    => $image_file_name,
        format  => $c->crp->trimmed_param('image_format'),
    });
    $component->create_or_update;
    $c->_return_to_page_editor;
}

use CRP::Util::Graphics;
sub _process_uploaded_image {
    my $c = shift;

    my $image = $c->req->upload('upload');
    return unless $image->size;

    if($image->size > ($c->config->{olc}->{max_image_file_size} || 10_000_000)) {
        $c->validation->error(upload => ['file_too_large']);
        return;
    }

    use File::Temp;
    my($fh, $temp_file) = tmpnam();
    close $fh;

    my $actual_file_name;
    my $error;
    try {
        $image->move_to($temp_file);
        if(CRP::Util::Graphics::limit_size(
                $temp_file,
                $c->config->{olc}->{max_image_width} || 1200,
                $c->config->{olc}->{max_image_height} || 1200,
            )) {
            use File::Copy;
            $actual_file_name = $c->_get_unique_uploaded_image_file_name($c->req->upload('upload')->filename);
            move $temp_file, $actual_file_name or die "Failed to move '$temp_file' to '$actual_file_name': $!";
        }
        else {
            $c->validation->error(upload => ['invalid_image_file']);
        }
    }
    catch {
        $error = $_;
    };
    unlink $temp_file;
    die $error if $error;

    $actual_file_name =~ s/^.*\///;
    return $actual_file_name;
}

sub _get_unique_uploaded_image_file_name {
    my $c = shift;
    my($proposed_name) = @_;

    my $base_dir = $c->crp->path_for_public_file($c->crp->olc_uploaded_image_location);
    return CRP::Util::Misc::get_unique_file_name($base_dir, $proposed_name);
}

1;

