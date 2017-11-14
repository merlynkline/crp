package CRP::Util::Graphics;

use warnings;
use strict;

use Carp;

use Imager;
use Imager::QRCode;

sub resize {
    my($filename, $width, $height) = @_;

    my $error_code = _resize_or_return_error_code(@_);
    return ! $error_code;
}

sub _resize_or_return_error_code {
    my($filename, $width, $height) = @_;

    my $img = Imager->new();
    $img->read(file => $filename) or return 'BAD_FILE';
    return _resize_img_or_return_error_code($img, $filename, $width, $height);
}

sub _resize_img_or_return_error_code {
    my($img, $filename, $width, $height) = @_;

    $img = $img->scale(xpixels => $width, ypixels => $height, qtype => 'mixing');
    $img = $img->crop(width  => $width, height => $height);
    unless($img->write(file => $filename, type => 'jpeg')) {
        warn "Image write failed: " . $img->errstr;
        return 'WRITE_FAIL';
    }
    return;
}

sub limit_size {
    my($filename, $width, $height) = @_;

    my $error_code = _limit_size_or_return_error_code(@_);
    return ! $error_code;
}

sub _limit_size_or_return_error_code {
    my($filename, $width, $height) = @_;

    my $img = Imager->new();
    $img->read(file => $filename) or return 'BAD_FILE';
    return if $img->getwidth <= $width && $img->getheight <= $height;
    return _resize_img_or_return_error_code($img, $filename, $width, $height);
}

sub qr_code_link_jpeg_tmp_file {
    my($url) = @_;

    croak "No url supplied for " . __PACKAGE__ . "::qr_code_link_jpeg_tmp_file()" unless $url;
    use File::Temp;
    my $qrcode = Imager::QRCode->new;
    my $img = $qrcode->plot($url);
    my($fh, $temp_file) = tmpnam();
    $img->write(fh => $fh, type => 'jpeg') or die "Image write to '$temp_file' failed: " . $img->errstr;
    close $fh;
    if(wantarray) {
        return($temp_file, $img->getwidth, $img->getheight);
    }
    return $temp_file;
}

sub compose_fb_profile_pic {
    my($params) = @_;

    my $logo_img = Imager->new();
    $logo_img->read(file => $params->{image_dir} . '/CRPLogoGlow.png');

    my $img = Imager->new();
    $img->read(file => $params->{profile_pic});

    $img = $img->crop(
        left    => $params->{x},
        top     => $params->{y},
        right   => $params->{r},
        bottom  => $params->{b},
    );
    $img = $img->scale(scalefactor => $params->{z});

    $img->compose(
        src => $logo_img,
        tx  => $img->getwidth - $logo_img->getwidth,
        ty  => $img->getheight - $logo_img->getheight,
    );

    my $image_data;
    $img->write(
        type            => 'jpeg',
        jpegquality     => 90,
        jpeg_optimize   => 1,
        data            => \$image_data,
    ) or die $img->errstr;
    return $image_data;
}

1;


