package CRP::Util::PDFMarkUp;
use Moose;

has file_path => (is => 'ro', isa => 'Str', required => 1);
has test_mode => (is => 'ro', isa => 'Bool', default => 0);

has _temp_file_list => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        _add_temp_file  => 'push',
        _temp_files     => 'elements',
    },
);
has _data   => (is => 'rw', isa => 'HashRef');
has _markup => (is => 'rw', isa => 'ArrayRef', default => sub { [] });
has _pdf    => (is => 'rw', isa => 'PDF::API2');

use constant QRCODE_SCALE => 0.33;

use Mojo::Util;

use warnings;
use strict;

use Carp;
use PDF::API2;

use CRP::Util::Graphics;

sub DEMOLISH {
    my $self = shift;

    foreach my $temp_file ($self->_temp_files) {
        unlink $temp_file;
    }
}

sub fill_template {
    my $self = shift;
    my($crp_data) = @_;

    $self->_pdf(PDF::API2->open($self->file_path)) or croak "Couldn't read PDF file '" . $self->file_path . "': $!";
    $self->_load_markup;
    $self->_data($crp_data // {});
    $self->_markup_pdf;
    return $self->_pdf->stringify;
}

sub _load_markup {
    my $self = shift;
    
    my $file_path = $self->file_path;
    $file_path =~ s{\.pdf$}{};
    $file_path .= '.mark';
    my $markup = [];
    if(-r $file_path) {
        $markup = Mojo::Util::slurp($file_path);
        $markup = eval $markup;
        warn "PDF Markup evaluation error in '$file_path': $@" if $@;
        $markup = [ $markup ] unless ref $markup eq 'ARRAY';
    }
    $self->_markup($markup);
}

sub _markup_pdf {
    my $self = shift;
    my($markup, $data) = @_;

    foreach my $markup_item(@{$self->_markup}) {
        my $action = $markup_item->{action} // 'text';
        if   ($action eq 'text')                { $self->_markup_pdf_text($markup_item); }
        elsif($action eq 'qrcode_signature')    { $self->_markup_pdf_qrcode_signature($markup_item); }
        elsif($action eq 'qrcode')              { $self->_markup_pdf_qrcode($markup_item); }
    }
}

sub _markup_pdf_text {
    my $self = shift;
    my($markup_item) = @_;

    my $string = $self->_replace_place_holders($markup_item->{text} || '', $self->_data);
    my $page = $self->_pdf->openpage($markup_item->{page} || 1);
    my $font = $self->_pdf->corefont($markup_item->{font} || 'Helvetica', -dokern => 1);
    my $text = $page->text();
    $text->textlabel(
        $markup_item->{x},
        $markup_item->{y},
        $font,
        $markup_item->{size} || 12,
        $string,
        -align => $markup_item->{align} || 'left',
        -color => $markup_item->{colour} || '#000',
    );
}

sub _replace_place_holders {
    my $self = shift;
    my($text, $data) = @_;

    if($self->test_mode) {
        $text =~ s{\[%\s*(.+?)\s*%]}{"[[ $1 ]]"}gsmixe;
    }
    else {
        $text =~ s{\[%\s*(.+?)\s*%]}{$data->{$1} || ''}gsmixe;
    }
    return $text;
}

sub _markup_pdf_qrcode_signature {
    my $self = shift;
    my($markup_item) = @_;

    my $font_size = $markup_item->{size} || 12;
    my $line_height = $font_size * 1.2;
    my $data = $self->_data;

    my $signature_url = $self->test_mode
        ? 'http://www.kidsreflexology.co.uk/me/-175347/certificate' # Long enough to generate a typically sized QRCode
        : $data->{signature_url} // '';
    my($width, $height) = $self->_add_qr_code_link(
        $signature_url, $markup_item->{page} || 1, $markup_item->{x}, $markup_item->{y}
    );

    my $text_markup_item = { %$markup_item };

    $text_markup_item->{text} = $text_markup_item->{text1};
    $text_markup_item->{x} += $width * QRCODE_SCALE;
    $text_markup_item->{y} += 10 * QRCODE_SCALE; # Width of QRCode white border
    $text_markup_item->{y} += $line_height;
    $self->_markup_pdf_text($text_markup_item);

    $text_markup_item->{text} = $text_markup_item->{text2};
    $text_markup_item->{y} -= $line_height;
    $self->_markup_pdf_text($text_markup_item);
}

sub _add_qr_code_link {
    my $self = shift;
    my($url, $page_number, $x, $y) = @_;

    my ($file_name, $width, $height) = CRP::Util::Graphics::qr_code_link_jpeg_tmp_file($url);
    my $page = $self->_pdf->openpage($page_number || 1);
    my $gfx = $page->gfx;
    my $image = $self->_pdf->image_jpeg($file_name);
    $gfx->image($image, $x, $y, QRCODE_SCALE);
    $self->_add_temp_file($file_name);
    return($width, $height);
}

sub _markup_pdf_qrcode {
    my $self = shift;
    my($markup_item) = @_;

    my $data = $self->_data;

    my $string = $self->test_mode
        ? 'http://www.kidsreflexology.co.uk/me/-175347/icourse/88' # Long enough to generate a typically sized QRCode
        : $markup_item->{text} // '';
    $string = $self->_replace_place_holders($string, $self->_data);
    return unless $string;
    $self->_add_qr_code_link(
        $string, $markup_item->{page} || 1, $markup_item->{x}, $markup_item->{y}
    );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;


