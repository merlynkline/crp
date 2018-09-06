package CRP::Controller::API;
use Mojo::Base 'Mojolicious::Controller';

use CRP::Model::OLC::CourseSet;
use CRP::Model::OLC::Course;
use CRP::Model::OLC::Module;
use CRP::Model::OLC::Page;
use CRP::Model::OLC::Component;
use CRP::Model::OLC::ResourceStore;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $c = shift;

    return 1 if $c->param('key') eq $c->config->{API}->{secret};
    $c->reply->not_found;
    return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub courses {
    my $c = shift;

    my $courses = [ map
        {
            name                => $_->name,
            title               => $_->title,
            guid                => $_->guid,
            last_update_date    => $_->last_update_date,
        }, @{CRP::Model::OLC::CourseSet->new(dbh => $c->crp->model)->all}
    ];

    $c->render(json => $courses);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub course_state {
    my $c = shift;

    my $course = CRP::Model::OLC::Course->new(dbh => $c->crp->model, guid => $c->param('guid'));
    my $resource_store = CRP::Model::OLC::ResourceStore->new(c => $c);

    $c->render(json => $course->state_data($resource_store));
}

my $OBJECT_CONFIG = {
    course    => 'Course',
    module    => 'Module',
    page      => 'Page',
    component => 'Component',
};

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub resource {
    my $c = shift;

    my $type = $c->param('type');
    my $name = $c->param('name');

    my $file = CRP::Model::OLC::ResourceStore->new(c => $c)->file_path_relative_to_static($name, $type);
    my $asset = $c->app->static->file($file);
    $c->reply->asset($asset);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub object_definition {
    my $c = shift;

    my $type = $c->param('type');
    my $class = $OBJECT_CONFIG->{$type} or die "Unknown object type '$type'";
    $class = "CRP::Model::OLC::$class";

    my $guid = $c->param('guid');
    my $object = $class->new(dbh => $c->crp->model, guid => $guid) or die "Couldn't find object type '$type' with guid '$guid'";

    $c->render(json => $object->serialised);
}

1;

