
package CRP::Controller::OLCAdmin::Component::Image;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use CRP::Model::OLC::Component;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $extra_data = {
        files         => $c->_get_file_list(),
        file_base_url => $c->url_for($c->crp->olc_uploaded_image_location)->to_abs,
    };
    $c->_display_component_editor('o_l_c_admin/component/editor/image', $extra_data);
}

sub _get_file_list {
    my $c = shift;

    my @files;
    use File::Find;
    my $base_dir = $c->crp->path_for_public_file($c->crp->olc_uploaded_image_location);
    find({wanted => sub {
                s{^$base_dir}{};
                push @files, $1 if m{^/([^.].+)$};
            },
            no_chdir => 1,
        },
        $base_dir
    );
    return \@files;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub save {
    my $c = shift;

    my $component = $c->_component;
    $component->data_version(1);
    $component->name($c->crp->trimmed_param('name'));
    $component->data({
        file    => $c->crp->trimmed_param('image_file'),
        format  => $c->crp->trimmed_param('image_format'),
    });
    $component->create_or_update;
    $c->_return_to_page_editor;
}

1;

