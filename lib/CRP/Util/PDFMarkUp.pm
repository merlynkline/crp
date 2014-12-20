package CRP::Util::PDFMarkUp;
use Moose;

has file_path => (is => 'ro', isa => 'Str', required => 1);

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

use Mojo::Util;

use warnings;
use strict;

use Carp;
use PDF::API2;

use CRP::Util::Graphics;

sub DESTROY {
    my $self = shift;

    foreach my $temp_file ($self->_temp_files) {
        unlink $temp_file;
    }
}

sub fill_template {
    my $self = shift;
    my($crp_data) = @_;

    my $pdf = PDF::API2->open($self->file_path) or croak "Couldn't read PDF file '" . $self->file_path . "': $!";
    $self->_load_markup;
    $self->_extract_crp_data($crp_data) if $crp_data;
    $self->_markup_pdf($pdf);
    return $pdf->stringify;
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
        $markup = [ $markup ] unless ref $markup eq 'ARRAY';
    }
    $self->_markup($markup);
}

sub _markup_pdf {
    my $self = shift;
    my($pdf, $markup, $data) = @_;

    foreach my $markup_item(@{$self->_markup}) {
        my $action = $markup_item->{action} // 'text';
        if   ($action eq 'text')                { $self->_markup_pdf_text($pdf, $markup_item); }
        elsif($action eq 'qrcode_signature')    { $self->_markup_pdf_qrcode_signature($pdf, $markup_item); }
    }
}

sub _markup_pdf_text {
    my $self = shift;
    my($pdf, $markup_item) = @_;

    my $string = _replace_place_holders($markup_item->{text} || '', $self->_data);
    my $page = $pdf->openpage($markup_item->{page} || 1);
    my $font = $pdf->corefont($markup_item->{font} || 'Helvetica', -dokern => 1);
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
    my($text, $data) = @_;

    if($data) {
        $text =~ s{\[%\s*(.+?)\s*%]}{$data->{$1} || ''}gsmixe;
    }
    else {
        # Test mode
        $text =~ s{\[%\s*(.+?)\s*%]}{"[[ $1 ]]"}gsmixe;
    }
    return $text;
}

sub _extract_crp_data {
    my $self = shift;
    my($crp_data) = @_;

    my $data = {};
    $data->{$_} = $crp_data->{$_} foreach(qw(email url));

    my $profile = $crp_data->{profile};
    $data->{$_} = $profile->$_ foreach(qw(name postcode telephone mobile));

    my $phone_numbers = $profile->telephone;
    $phone_numbers .= ' / ' if $phone_numbers && $profile->mobile;
    $phone_numbers .= $profile->mobile // '';
    $data->{phone_numbers} = $phone_numbers;

    my $one_line_address = $profile->address;
    $one_line_address =~ s{\s*[\r\n]+\s*}{, }gsm;
    $one_line_address =~ s{^\s*|\s*$}{}g;
    $data->{one_line_address} = $one_line_address;

    $self->_data($data);
}

sub _markup_pdf_qrcode_signature {
    my $self = shift;
    my($pdf, $markup_item) = @_;

    my $font_size = $markup_item->{size} || 12;
    my $line_height = $font_size * 1.2;
    my $data = $self->_data;
    my $text_markup_item = { %$markup_item };

    $text_markup_item->{text} = $text_markup_item->{text1};
    $text_markup_item->{x} += 42;   # Space for width of QRCode
    $text_markup_item->{y} += 3.5;  # Width of QRCode white border
    $text_markup_item->{y} += $line_height;
    $self->_markup_pdf_text($pdf, $text_markup_item);

    $text_markup_item->{text} = $text_markup_item->{text2};
    $text_markup_item->{y} -= $line_height;
    $self->_markup_pdf_text($pdf, $text_markup_item);

    $self->_add_qr_code_link(
        $pdf,
        $data ? $data->{signature_url} : 'http://www.kidsreflexology.co.uk/me/-175347/certificate',
        $markup_item->{page} || 1,
        $markup_item->{x},
        $markup_item->{y},
    );
}

sub _add_qr_code_link {
    my $self = shift;
    my($pdf, $url, $page_number, $x, $y) = @_;

    my $file_name = CRP::Util::Graphics::qr_code_link_jpeg_tmp_file($url);
    my $page = $pdf->openpage($page_number || 1);
    my $gfx = $page->gfx;
    my $image = $pdf->image_jpeg($file_name);
    $gfx->image($image, $x, $y, 0.33);
    $self->_add_temp_file($file_name);
}

1;


