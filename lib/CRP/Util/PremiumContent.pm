package CRP::Util::PremiumContent;
use Moose;

use Carp;
use IO::Dir;

has paths   => (is => 'ro', isa => 'ArrayRef', init_arg => undef, lazy => 1, builder => '_build_paths');
has c       => (is => 'ro', required => 1);


sub _build_paths {
    my $self = shift;

    my @paths;
    my $base_dir = $self->c->app->home->rel_file('templates/premium');

    my $dir = IO::Dir->new($base_dir);
    while(defined(my $entry = $dir->read)) {
        my $sub_dir = "$base_dir/$entry";
        if(-d $sub_dir) {
            push @paths, $entry if -f "$sub_dir/welcome.html.ep" and -f "$sub_dir/access.html.ep";
        }
    }

    return \@paths;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

