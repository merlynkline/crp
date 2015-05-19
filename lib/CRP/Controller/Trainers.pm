package CRP::Controller::Trainers;

use Mojo::Base 'Mojolicious::Controller';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub authenticate {
    my $c = shift;

    return 1 if $c->stash('login_record')->profile->instructor_trainer;
    $c->render(text => "Sorry - you aren't authorised to see this page", status => 403);
    return 0;
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub courses {
    my $c = shift;

    my $profile = $c->crp->load_profile;
    my $courses = $profile->instructors_courses;
    $c->stash(advertised_list   => _date_order_list(scalar $courses->get_advertised_set));
    $c->stash(draft_list        => _date_order_list(scalar $courses->get_draft_set));
    $c->stash(past_list         => _date_order_list(scalar $courses->get_past_set));
    $c->stash(canceled_list     => _date_order_list(scalar $courses->get_canceled_set));
}

sub _date_order_list {
    my($result_set) = @_;

    return [ $result_set->search(undef, { order_by => {-asc => 'start_date'} }) ];
}


1;

