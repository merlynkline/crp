package CRP::Helper::Markdown;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Text::Markdown 'markdown';

sub register {
    my $c = shift;
    my($app, $config) = @_;

    my %config = %$config if ref $config eq 'HASH';
    $app->helper(markdown => sub {
        my $c = shift;
        my $content = pop;

        my %this_config = (%config, @_);
        $content = $content->() if ref $content eq 'CODE';
        $content = markdown("$content", \%this_config);
        return Mojo::ByteStream->new($content);
    });
}

1;

