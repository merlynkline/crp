package CRP::Controller::API;
use Mojo::Base 'Mojolicious::Controller';

use CRP::Model::OLC::CourseSet;

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

1;

