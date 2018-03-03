package CRP::Controller::OLCAdmin::Component::Video;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use Try::Tiny;

use CRP::Util::Misc;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $dir = $c->app->home->rel_file($c->crp->olc_uploaded_video_location)->to_string;
    my $extra_data = {
        files         => CRP::Util::Misc::get_file_list($dir, qr{^/([^.].*\.(?:mp4|wmv))$}i),
        file_base_url => $c->url_for($c->crp->olc_uploaded_video_thumb_location)->to_abs,
    };
    $c->_display_component_editor('o_l_c_admin/component/editor/video', $extra_data);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub save {
    my $c = shift;

    my $video_file_name = $c->_process_uploaded_video // $c->crp->trimmed_param('video_file');
    $c->validation->error(upload => ['file_required']) unless $c->validation->has_error || $video_file_name;
    return $c->edit if $c->validation->has_error;
    die "Couldn't process video" unless $video_file_name;

    my $component = $c->_component;
    $component->data_version(1);
    $component->name($c->crp->trimmed_param('name'));
    $component->data({
        file    => $video_file_name,
        title   => $c->crp->trimmed_param('title'),
    });
    $component->create_or_update;
    $c->_return_to_page_editor;
}

sub _process_uploaded_video {
    my $c = shift;

    my $validation_error;
    my $actual_video_file_name;

    my $video = $c->req->upload('upload');

    if($video->size > ($c->config->{olc}->{max_video_file_size} || 100_000_000)) {
        $validation_error = 'file_too_large';
    }
    elsif($video->size < 1) {
        return;
    }
    else {
        use File::Temp;
        my($fh, $temp_file) = tmpnam();
        close $fh;

        my $error;
        try {
            $video->move_to($temp_file);
            use File::Copy;
            $actual_video_file_name = $c->_get_unique_uploaded_video_file_name($c->req->upload('upload')->filename);
            move $temp_file, $actual_video_file_name or die "Failed to move '$temp_file' to '$actual_video_file_name': $!";
        }
        catch {
            warn "Couldn't upload video: $_";
            $validation_error = 'invalid_video';
        };
        unlink $temp_file;

        if( ! $validation_error) {
            $validation_error = $c->_make_video_thumbnail($actual_video_file_name);
        }

        if($validation_error) {
            unlink $actual_video_file_name;
            unlink $c->_get_video_thumbnail_path($actual_video_file_name);
        }
    }

    if($validation_error) {
        $c->validation->error(upload => [$validation_error]);
        return;
    }

    $actual_video_file_name =~ s/^.*\///;
    return $actual_video_file_name;
}

sub _make_video_thumbnail {
    my $c = shift;
    my($video_path) = @_;

    my $validation_error;
    try {
        use Video::FrameGrab;
        use Imager;

        my $grabber = Video::FrameGrab->new(video => $video_path) or die "Unrecognised video format";
        my @snap_frames;
        my @snap_times = $grabber->equidistant_snap_times(8);
        foreach my $snap_time (@snap_times) {
            my $jpeg_snapshot = $grabber->snap($snap_time);
            my $imager = Imager->new;
            $imager->read(data => $jpeg_snapshot);
            $imager = $imager->scale(xpixels => 200);
            push @snap_frames, $imager;
        }
        my $imager = Imager->new;
        $imager->write_multi(
            {
                file      => $c->_get_video_thumbnail_path($video_path),
                type      => 'gif',
                gif_delay => 50,
                gif_loop  => 0
            },
            @snap_frames
        ) or die $imager->errstr;
    }
    catch {
        $validation_error = 'invalid_video';
    };

    return $validation_error;
}

sub _get_unique_uploaded_video_file_name {
    my $c = shift;
    my($proposed_name) = @_;

    my $base_dir = $c->app->home->rel_file($c->crp->olc_uploaded_video_location)->to_string;
    return CRP::Util::Misc::get_unique_file_name($base_dir, $proposed_name);
}

sub _get_video_thumbnail_path {
    my $c = shift;
    my($video_path) = @_;

    $video_path =~ s/^.*\///;
    my $thumb_path = $c->crp->path_for_public_file($c->crp->olc_uploaded_video_thumb_location) . "/$video_path.thumb.gif";
}

1;

