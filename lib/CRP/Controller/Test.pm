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
    use File::Find;
    my $base_dir = $c->app->home->rel_file('pdfs');
    find({ wanted => sub {
                s{^$base_dir}{};
                push @files, $_ if m{^[^.].*\.pdf$};
            },
            no_chdir => 1,
        },
        $base_dir
    );
    $c->stash(pdflist_members => \@files);
    return $c->template('test/list_pdfs');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use CRP::Util::PDFMarkUp;
sub pdf {
    my $c = shift;

    my $pdf = shift // $c->stash('pdf');
    $pdf = $c->app->home->rel_file("pdfs/$pdf");
    return $c->reply->not_found unless -r $pdf;

    my $pdf_doc = CRP::Util::PDFMarkUp->new(file_path => $pdf);
    $c->render_file(
        data                => $pdf_doc->fill_template,
        format              => 'pdf',
        content_disposition => $c->param('download') ? 'attachment' : 'inline',
    );
}

1;
