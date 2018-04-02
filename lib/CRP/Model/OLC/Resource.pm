package CRP::Model::OLC::Resource;
use Moose;
use namespace::autoclean;

use Carp;
use File::stat;

use DateTime;

has _resource_store => (is => 'ro', isa => 'CRP::Model::OLC::ResourceStore', init_arg => 'resource_store');
has name            => (is => 'ro');
has type            => (is => 'ro');

sub path_name {
    my $self = shift;
    my($name, $type) = @_;

    my $path = $self->_resource_store->file_base_path($self->type) . '/' . $self->name;
    return $self->_resource_store->c->app->home->rel_file($path)->to_string;
}

sub mtime {
    my $self = shift;
    my($name, $type) = @_;

    my $stat = stat($self->path_name) or croak "Could not stat '$type' resource '$name': $!";
    return DateTime->from_epoch(epoch => $stat->mtime);
}


__PACKAGE__->meta->make_immutable;

1;

