package CRP::Util::PDF;

use warnings;
use strict;

use Carp;
use CAM::PDF;

sub fill_template {
    my($file_path, $crp_data) = @_;


    my $pdf_object = CAM::PDF->new($file_path) or croak "Couldn't read PDF file '$file_path': $!";
    my $data = _extract_crp_data($crp_data);
    foreach my $page (1 .. $pdf_object->numPages()) {
        my $content = $pdf_object->getPageContent($page);
        $content = _replace_markers_in_content($content, $data);
        $pdf_object->setPageContent($page, $content);
    }
    return $pdf_object->toPDF;
}

sub _extract_crp_data {
    my($crp_data) = @_;

    my $profile = $crp_data->{profile};
    my $telephone = $profile->telephone;
    $telephone .= ' / ' if $telephone && $profile->mobile;
    $telephone .= $profile->mobile;
    my $data = {
        name        => $profile->name,
        telephone   => $telephone,
    };
    return $data;
}

sub _replace_markers_in_content {
    my($content, $data) = @_;

    while(my($key, $value) = each %$data) {
        my $string      = _expand_unicode("[% $key %]");
        my $replacement = _expand_unicode($value);
        $content =~ s{\((.*?)\Q$string\E(.*?)\)}{($1$replacement$2)}gsmx;
    }
    return $content;
}


sub _expand_unicode {
    my($string) = @_;

    $string =~ s{(.)}{\\000$1}gsmx;
    return $string;
}

1;

