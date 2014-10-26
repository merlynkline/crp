use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('CRP');

my $home_page_text = "the children's reflexology programme";
$t->get_ok('/')->status_is(200)->content_like(qr/$home_page_text/i);

$t->get_ok('/page/__should__not__exist')->status_is(404);
$t->get_ok('/page/carers')->status_is(200);

done_testing();
