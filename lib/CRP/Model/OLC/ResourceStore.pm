package CRP::Model::OLC::ResourceStore;
use Moose;
use namespace::autoclean;

use Carp;
use File::stat;

use DateTime;

use CRP::Model::OLC::Resource;

has c => (is => 'ro');

my %FILE_PATHS = (
    image       => 'public/olc/images/uploaded',
    pdf         => 'pdfs/olc/uploaded',
    video       => 'videos/olc/uploaded',
    video_thumb => 'public/olc/video-thumbs/uploaded',
);

sub get_resource {
    my $self = shift;
    my($name, $type) = @_;

    return CRP::Model::OLC::Resource->new(resource_store => $self, name => $name, type => $type);
}

sub get_resource_list {
    my $self = shift;
    my($type) = @_;

    my $files = CRP::Util::Misc::get_file_list($self->file_base_path($type));
    return [ map { CRP::Model::OLC::Resource->new(resource_store => $self, name => $_, type => $type) } @$files ];
}

sub file_base_path {
    my $self = shift;
    my($type) = @_;

    my($class, $sub_class) = $self->_get_class($type);
    return $FILE_PATHS{$sub_class};
}

sub url_base {
    my $self = shift;
    my($type) = @_;

    my($class, $sub_class) = $self->_get_class($type);

    if($class eq 'file' && ($sub_class eq 'image' || $sub_class eq 'video_thumb')) {
        my $base = $self->file_base_path($type);
        $base =~ s{^public/}{};
        return $self->c->url_for($base)->to_abs;
    }

    croak "url_base doesn't know about type '$type' yet";
}

sub _get_class {
    my $self = shift;
    my($type) = @_;

    my($class, $sub_class) = split qr{\s*/\s*}, $type;
    croak "Unknown resource class '$class' in '$type'" unless $class eq 'file';
    croak "Unknown resource sub-class '$sub_class' in '$type'" unless exists $FILE_PATHS{$sub_class};
    return($class, $sub_class);
}

__PACKAGE__->meta->make_immutable;

1;

