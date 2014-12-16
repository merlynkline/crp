package CRP::Util::PDF;

use Mojo::Util;

use warnings;
use strict;

use Carp;
use PDF::API2;

sub fill_template {
    my($file_path, $crp_data) = @_;

    my $mark_up = _load_markup($file_path);
    my $pdf = PDF::API2->open($file_path) or croak "Couldn't read PDF file '$file_path': $!";
    my $data = _extract_crp_data($crp_data) if $crp_data;
    _markup_pdf($pdf, $mark_up, $data);
    return $pdf->stringify;
}

sub _load_markup {
    my($file_path)= @_;

    $file_path =~ s{\.pdf$}{};
    $file_path .= '.mark';
    my $mark_up = [];
    if(-r $file_path) {
        $mark_up = Mojo::Util::slurp($file_path);
        $mark_up = eval $mark_up;
        $mark_up = [ $mark_up ] unless ref $mark_up eq 'ARRAY';
    }
    return $mark_up;
}

sub _markup_pdf {
    my($pdf, $mark_up, $data) = @_;

    foreach my $mark_up_item(@$mark_up) {
        my $action = $mark_up_item->{action} // 'text';
        if($action eq 'text')     { _markup_pdf_text($pdf, $mark_up_item, $data); }
    }
}

sub _markup_pdf_text {
    my($pdf, $mark_up_item, $data) = @_;

    my $string = _replace_place_holders($mark_up_item->{text} || '', $data);
    my $page = $pdf->openpage($mark_up_item->{page} || 1);
    my $font = $pdf->corefont($mark_up_item->{font} || 'Helvetica', -dokern => 1);
    my $text = $page->text();
    $text->textlabel(
        $mark_up_item->{x} || 100,
        $mark_up_item->{y} || 100,
        $font,
        $mark_up_item->{size} || 12,
        $string,
        -align => $mark_up_item->{align} || 'left'
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

    return $data;
}

1;


