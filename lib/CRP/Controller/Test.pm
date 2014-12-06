package CRP::Controller::Test;
use Mojo::Base 'Mojolicious::Controller';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $self = shift;

    return 1 if $self->app->mode eq 'development';
    $self->reply->not_found;
    return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    $c->render;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub template {
    my $c = shift;

    my $template = shift || $c->stash('template');
    $c->render(template => $template);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub list_pdfs {
    my $c = shift;

    my @files;
    my $dir = $c->app->home->rel_file('pdfs/members/');
    opendir my $dirh, $dir or die "Can't open directory '$dir': $!";
    while (my $file = readdir $dirh) {
        push @files, "members/$file" if $file =~ m{^[^.].*\.pdf$};
    }
    closedir $dirh;
    $c->stash(pdflist_members => \@files);
    return $c->template('test/list_pdfs');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDF;
sub pdf {
    my $c = shift;

    my $pdf = shift // $c->stash('pdf');
    $pdf = $c->app->home->rel_file("pdfs/$pdf");
    return $c->reply->not_found unless -r $pdf;

    my $pdf_doc = CRP::Util::PDF::fill_template($pdf);
    $c->render_file(
        data                => $pdf_doc,
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
    );
}

1;
