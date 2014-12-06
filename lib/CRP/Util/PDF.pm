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
    $crp_data = _extract_crp_data($crp_data);
    _markup_pdf($pdf, $mark_up, $crp_data);
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
    my($pdf, $mark_up, $crp_data) = @_;

    foreach my $mark_up_item(@$mark_up) {
        my $action = $mark_up_item->{action} // 'text';
        if($action eq 'text')     { _markup_pdf_text($pdf, $mark_up_item, $crp_data); }
    }
}

sub _markup_pdf_text {
    my($pdf, $mark_up_item, $crp_data) = @_;

    my $string = _replace_place_holders($mark_up_item->{text} || '', $crp_data);
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
    my($text, $crp_data) = @_;

    $text =~ s{\[%\s*(.+?)\s*%]}{$crp_data->{$1} || ''}gsmixe;
    return $text;
}

sub _extract_crp_data {
    my($crp_data) = @_;

    my $profile = $crp_data->{profile};
    my $telephone = $profile->telephone;
    $telephone .= ' / ' if $telephone && $profile->mobile;
    $telephone .= $profile->mobile;
    my $one_line_address = $profile->address;
    $one_line_address =~ s{\s*[\r\n]+\s*}{, }gsmx;
    my $data = {
        name                => $profile->name,
        postcode            => $profile->postcode,
        telephone           => $telephone,
        one_line_address    => $one_line_address,
    };
    $data->{$_} = $crp_data->{$_} foreach(qw(email url));
    return $data;
}

1;


