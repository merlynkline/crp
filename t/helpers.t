use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('CRP');
my $c = $t->app->build_controller;
my $mode = $c->app->mode;

my $crp_helper = $c->crp;

# stash_list
is_deeply($crp_helper->stash_list('test_list'), [], 'stash_list no value');
$c->stash('test_list' => 'one');
is_deeply($crp_helper->stash_list('test_list'), ['one'], 'stash_list one value');
$c->stash('test_list' => ['one', 'two']);
is_deeply($crp_helper->stash_list('test_list'), ['one', 'two'], 'stash_list two values');

# email_decorated
my $model = $crp_helper->model('Login');
can_ok($model, 'find');
is($crp_helper->email_decorated('test@example.com'), 'test@example.com');
is($crp_helper->email_decorated('test@example.com', 'tester'), 'tester <test@example.com>');

# email_to
my $test_email = $c->app->config->{test}->{email};
is($crp_helper->email_to('test@example.com'), " (Was to: test\@example.com) <$test_email>");
is($crp_helper->email_to('test@example.com', 'tester'), "tester (Was to: test\@example.com) <$test_email>");
$c->app->mode('production');
is($crp_helper->email_to('test@example.com'), 'test@example.com');
is($crp_helper->email_to('test@example.com', 'tester'), 'tester <test@example.com>');
$c->app->mode($mode);

# trimmed_param
foreach my $value (
    'value  value',
    ' value  value',
    'value  value   ',
    '  value  value  ',
    "\tvalue  value",
) {
    $c->param('test', $value);
    is($crp_helper->trimmed_param('test'), 'value  value', "trimmed_parami for '$value'");
}
$c->param('test', undef);
is($crp_helper->trimmed_param('test'), undef, "trimmed_parami for undef");


done_testing();
