package CRP::Controller::OLCAdmin;

use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

use CRP::Model::OLC::Course;
use CRP::Model::OLC::CourseSet;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    $c->stash(course_list => CRP::Model::OLC::CourseSet->new(dbh => $c->crp->model)->view_data);

}


1;

