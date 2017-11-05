package CRP::Controller::OLCAdmin::Component::Heading;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Role -with;
with 'CRP::Controller::OLCAdmin::EditorRole';
with 'CRP::Controller::OLCAdmin::Component::EditorRole';

use CRP::Model::OLC::Component;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub edit {
    my $c = shift;

    my $component = CRP::Model::OLC::Component->new({dbh => $c->crp->model, id => $c->_component_id});
    $c->render(text => "Edit heading");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

