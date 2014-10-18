package CRP::Command::migrate;
use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptions :config no_auto_abbrev no_ignore_case);

has description => "Wrapper for dbic-migration.\n";
has usage       => <<"EOF";
(useage message here)
EOF

sub run {
  my $self = shift;

  # Options
  local @ARGV = @_;
  my $verbose;
  GetOptions('v|verbose' => sub { $verbose = 1 });

  print "NOT MIGRATING NUFFIN\n";
  my $config = $self->app->plugin('Config');
  print "Cookie: ", $config->{session_cookie_name}, "\n";
  print "dbu: ", $config->{database}->{username}, "\n";
}

1;


