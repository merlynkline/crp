package CRP::Controller::OLCAdmin::Component::Video;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';
use CRP::Model::OLC::ResourceStore;

use Try::Tiny;

use CRP::Util::Misc;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $resource_store = CRP::Model::OLC::ResourceStore->new(c => $c);
    my $resources = $resource_store->get_resource_list('file/video');
    my $extra_data = {
        files         => [ map { $_->name } @$resources ],
        file_base_url => $resource_store->url_base('file/video_thumb'),
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

        my $resource_store = CRP::Model::OLC::ResourceStore->new(c => $c);
        my $error;
        try {
            die "Video must be MP4 H264+MP3" unless $video->filename =~ /\.mp4$/i;
            $video->move_to($temp_file);
            $actual_video_file_name = $resource_store->move_file_to_store($temp_file, $video->filename, 'file/video');
        }
        catch {
            warn "Couldn't upload video: $_";
            $validation_error = 'invalid_video';
        };
        unlink $temp_file;

        if( ! $validation_error) {
            $validation_error = $c->_make_video_thumbnail_and_banner($resource_store, $actual_video_file_name);
        }

        if($validation_error) {
            $resource_store->remove($actual_video_file_name, 'file/video');
            $resource_store->remove("$actual_video_file_name.thumb.gif", 'file/video_thumb');
            $resource_store->remove("$actual_video_file_name.thumb.jpg", 'file/video_thumb');
        }
    }

    if($validation_error) {
        $c->validation->error(upload => [$validation_error]);
        return;
    }

    return $actual_video_file_name;
}

sub _make_video_thumbnail_and_banner {
    my $c = shift;
    my($resource_store, $video_name) = @_;

    my $validation_error;
    my $banner_made;
    try {
        use Video::FrameGrab;
        use Imager;

        use File::Temp;
        my($fh, $temp_file) = tmpnam();
        close $fh;

        my $grabber = Video::FrameGrab->new(video => $resource_store->file_path($video_name, 'file/video')) or die "Unrecognised video format";
        my @snap_frames;
        my @snap_times = $grabber->equidistant_snap_times(8);
        foreach my $snap_time (@snap_times) {
            my $jpeg_snapshot = $grabber->snap($snap_time);
            my $imager = Imager->new;
            $imager->read(data => $jpeg_snapshot);
            unless($banner_made) {
                $banner_made = 1;
                $imager = $imager->scale(xpixels => 500);
                $imager->write(
                    file => $temp_file,
                    type => 'jpeg'
                ) or die 'Failed to write jpg banner: ' . $imager->errstr;
                $resource_store->move_file_to_store($temp_file, "$video_name.thumb.jpg", 'file/video_thumb');
            }
            $imager = $imager->scale(xpixels => 200);
            push @snap_frames, $imager;
        }
        my $imager = Imager->new;
        $imager->write_multi(
            {
                file      => $temp_file,
                type      => 'gif',
                gif_delay => 50,
                gif_loop  => 0
            },
            @snap_frames
        ) or die 'Failed to write gif thumbnail: ' . $imager->errstr;
        $resource_store->move_file_to_store($temp_file, "$video_name.thumb.gif", 'file/video_thumb');
    }
    catch {
        warn "Error processing video '$video_name': $_\n";
        $validation_error = 'invalid_video';
    };

    return $validation_error;
}

1;

