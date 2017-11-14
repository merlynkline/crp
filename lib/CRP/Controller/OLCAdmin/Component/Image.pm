
package CRP::Controller::OLCAdmin::Component::Image;

use Try::Tiny;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use CRP::Model::OLC::Component;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $extra_data = {
        files         => $c->_get_file_list(),
        file_base_url => $c->url_for($c->crp->olc_uploaded_image_location)->to_abs,
    };
    $c->_display_component_editor('o_l_c_admin/component/editor/image', $extra_data);
}

sub _get_file_list {
    my $c = shift;

    my @files;
    use File::Find;
    my $base_dir = $c->crp->path_for_public_file($c->crp->olc_uploaded_image_location);
    find({wanted => sub {
                s{^$base_dir}{};
                push @files, $1 if m{^/([^.].+)$};
            },
            no_chdir => 1,
        },
        $base_dir
    );
    return [sort {lc $a cmp lc $b} @files];
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
    my $try_count = 0;
    while(-f "$base_dir/$proposed_name") {
        $proposed_name =~ s/(^.+?)(\d*)(\.[^.]+)$/$1 . (($2 || 0) + 1) . $3/e;
        $try_count ++;
        $proposed_name = int(rand(10)) . $proposed_name if $try_count % 10 == 0;
    }

    return "$base_dir/$proposed_name";
}

1;

