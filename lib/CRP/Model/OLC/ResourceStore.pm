package CRP::Model::OLC::ResourceStore;
use Moose;
use namespace::autoclean;

use Carp;
use File::stat;

use DateTime;

use CRP::Model::OLC::Resource;

has app => (is => 'ro', isa => 'CRP');

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

sub _base_path {
    my $self = shift;
    my($type) = @_;

    my($class, $sub_class) = split qr{\s*/\s*}, $type;
    croak "Unknown resource class '$class' in '$type'" unless $class eq 'file';
    croak "Unknown resource sub-class '$sub_class' in '$type'" unless exists $FILE_PATHS{$sub_class};

    return $FILE_PATHS{$sub_class};
}

__PACKAGE__->meta->make_immutable;

1;

