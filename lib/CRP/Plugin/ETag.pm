package CRP::Plugin::ETag;
# http://showmetheco.de/articles/2010/10/adding-etag-caching-to-your-mojolicious-app.html

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream;

sub register {
    my ($self, $app) = @_; 

    $app->hook(
        after_dispatch => sub {
            my $self = shift;

            return unless $self->req->method eq 'GET';

            my $body = $self->res->body;
            return unless defined $body;

            my $our_etag = Mojo::ByteStream->new($body)->md5_sum;
            $self->res->headers->header('ETag' => $our_etag);

            my $browser_etag = $self->req->headers->header('If-None-Match');
warn "$our_etag : ", ($browser_etag || 'NONE') . ' : ', $self->req->url,"\n";;
            return unless $browser_etag && $browser_etag eq $our_etag;

            $self->res->code(304);
            $self->res->body('');
        }   
    );  
}

1;

