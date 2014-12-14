package CRP::Util::Graphics;

use warnings;
use strict;

use Carp;

use Imager;

sub resize {
    my($filename, $width, $height) = @_;

    my $error_code = _resize_or_return_error_code(@_);
    return ! $error_code;
}

sub _resize_or_return_error_code {
    my($filename, $width, $height) = @_;

    my $img = Imager->new();
    $img->read(file => $filename) or return 'BAD_FILE';
    $img = $img->scale(xpixels => $width, ypixels => $height, qtype => 'mixing');
    $img = $img->crop(width  => $width, height => $height);
    unless($img->write(file => $filename, type => 'jpeg')) {
        warn "Image write failed: " . $img->errstr;
        return 'WRITE_FAIL';
    }
    return;
}

1;


