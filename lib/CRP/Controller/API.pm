package CRP::Controller::API;
use Mojo::Base 'Mojolicious::Controller';

use CRP::Model::OLC::CourseSet;
use CRP::Model::OLC::Course;
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
sub course {
    my $c = shift;

    my $course = CRP::Model::OLC::Course->new(dbh => $c->crp->model, guid => $c->param('guid'));
    my $resource_store = CRP::Model::OLC::ResourceStore->new(c => $c);

    $c->render(json => $course->state_data($resource_store));
}

1;

