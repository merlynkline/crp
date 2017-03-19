use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use CRP;

my $t = Test::Mojo->new('CRP');
my $c = $t->app->build_controller;

my $dom_info = $c->config->{domain_names};
my @domain_names = keys %$dom_info;
my $main_url = 'https://www.kidsreflex.co.uk';

my   @url_tests = map { [ "https://www.$_"       => $dom_info->{$_} eq 'ssl' ] } @domain_names;
push @url_tests,  map { [ "http://www.$_"        => $dom_info->{$_} ne 'ssl' ] } @domain_names;
push @url_tests,  map { [ "https://$_"           => 0 ] }                        @domain_names;
push @url_tests,  map { [ "https://www.$_/"      => $dom_info->{$_} eq 'ssl' ] } @domain_names;
push @url_tests,  map { [ "https://www." . uc $_ => $dom_info->{$_} eq 'ssl' ] } @domain_names;
foreach my $test (@url_tests) {
    is(CRP::_is_good_url($c, Mojo::URL->new($test->[0])), ! ! $test->[1], "_is_ok_url($test->[0])");
}

@url_tests =     map { [ "https://www.$_" => ($dom_info->{$_} eq 'ssl' ? 'https' : 'http') . "://www.$_" ] } @domain_names;
push @url_tests, map { [ "http://$_"      => ($dom_info->{$_} eq 'ssl' ? 'https' : 'http') . "://www.$_" ] } @domain_names;
push @url_tests, map { [ "https://$_"     => ($dom_info->{$_} eq 'ssl' ? 'https' : 'http') . "://www.$_" ] } @domain_names;
push @url_tests, map { [ "http://$_"      => ($dom_info->{$_} eq 'ssl' ? 'https' : 'http') . "://www.$_" ] } @domain_names;
push @url_tests, map { [ "http://$_.junk" => $main_url ] }             @domain_names;
push @url_tests, map { [ "http://$_.junk:3000" => $main_url ] }        @domain_names;

foreach my $test (@url_tests) {
    is(CRP::_make_good_url($c, Mojo::URL->new($test->[0])), $test->[1], "_make_good_url($test->[0])");
}

done_testing();
