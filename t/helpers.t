use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('CRP');
my $c = $t->app->build_controller;

is_deeply($c->crp->stash_list('test_list'), [], 'stash_list no value');
$c->stash('test_list' => 'one');
is_deeply($c->crp->stash_list('test_list'), ['one'], 'stash_list one value');
$c->stash('test_list' => ['one', 'two']);
is_deeply($c->crp->stash_list('test_list'), ['one', 'two'], 'stash_list two values');


done_testing();
