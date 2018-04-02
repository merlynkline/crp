package CRP::Model::OLC::ResourceStore;
use Moose;
use namespace::autoclean;

use Carp;
use File::stat;

use DateTime;

use CRP::Model::OLC::Resource;
use CRP::Util::Misc;

has c => (is => 'ro');

my %FILE_TYPE_INFO = (
    image       => {
        path    => 'public/olc/images/uploaded',
    },
    pdf         => {
        path    => 'pdfs/olc/uploaded',
        match   => qr{^/([^.].*\.pdf)$}i,
    },
    video       => {
        path    => 'videos/olc/uploaded',
        match   => qr{^/([^.].*\.(?:mp4|wmv))$}i,
    },
    video_thumb => {
        path    => 'public/olc/video-thumbs/uploaded',
    },
);

sub get_resource {
    my $self = shift;
    my($name, $type) = @_;

    return CRP::Model::OLC::Resource->new(resource_store => $self, name => $name, type => $type);
}

sub get_resource_list {
    my $self = shift;
    my($type) = @_;

    my($class, $sub_class) = $self->_get_class($type);

    my $files = CRP::Util::Misc::get_file_list($self->_file_base_path($type), $FILE_TYPE_INFO{$sub_class}->{match});
    return [ map { CRP::Model::OLC::Resource->new(resource_store => $self, name => $_, type => $type) } @$files ];
}

sub _file_base_path {
    my $self = shift;
    my($type) = @_;

    my($class, $sub_class) = $self->_get_class($type);
    return $FILE_TYPE_INFO{$sub_class}->{path};
}

sub file_path {
    my $self = shift;
    my($name, $type) = @_;

    return $self->c->app->home->rel_file($self->_file_base_path($type) . "/$name");
}

sub file_path_relative_to_static {
    my $self = shift;
    my($name, $type) = @_;

    my $static_path = $self->c->app->static->paths->[0];
    my $file_path = $self->file_path($name, $type);
    return $self->file_path($name, $type)->to_rel($static_path);
}

sub url_base {
    my $self = shift;
    my($type) = @_;

    my($class, $sub_class) = $self->_get_class($type);

    if($class eq 'file' && ($sub_class eq 'image' || $sub_class eq 'video_thumb')) {
        my $base = $self->_file_base_path($type);
        $base =~ s{^public/}{};
        return $self->c->url_for($base)->to_abs;
    }

    croak "url_base doesn't know about type '$type' yet";
}

sub move_file_to_store {
    my $self = shift;
    my($file, $name, $type) = @_;

    my($class, $sub_class) = $self->_get_class($type);

    my $base_dir = $self->_file_base_path($type);
    my $actual_name = CRP::Util::Misc::get_unique_file_name($base_dir, $name);
    use File::Copy;
    move $file, "$base_dir/$actual_name" or die "Failed to move '$file' to '$actual_name': $!";
    return $actual_name;
}

sub remove {
    my $self = shift;
    my($name, $type) = @_;

    unlink $self->file_path($name, $type);
}

sub _get_class {
    my $self = shift;
    my($type) = @_;

    my($class, $sub_class) = split qr{\s*/\s*}, $type;
    croak "Unknown resource class '$class' in '$type'" unless $class eq 'file';
    croak "Unknown resource sub-class '$sub_class' in '$type'" unless exists $FILE_TYPE_INFO{$sub_class};
    return($class, $sub_class);
}

__PACKAGE__->meta->make_immutable;

1;

