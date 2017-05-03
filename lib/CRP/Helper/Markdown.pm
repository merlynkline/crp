package CRP::Helper::Markdown;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Text::Markdown 'markdown';

sub register {
    my $c = shift;
    my($app) = @_;

    $app->helper(markdown => sub {
        my($c, $block) = @_;

        my $result = $block->()->to_string;
        $result = markdown($result, {
            empty_element_suffix => '/>',
            tab_width            => 2,
        });
        return Mojo::ByteStream->new($result);
    });
}

1;

