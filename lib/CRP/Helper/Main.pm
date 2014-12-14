package CRP::Helper::Main;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use CRP::Util::WordNumber;

sub register {
    my $c = shift;
    my($app) = @_;

    # Get a value from the stash, always returning a listref
    $app->helper(
        'crp.stash_list' => sub {
            my $c = shift;
            my $var_value = $c->stash($_[0]);
            return [] unless $var_value;
            $var_value = [ $var_value ] unless ref $var_value;
            return $var_value;
        }
    );

    # database connection prefork-safe with DBIx::Connector
    my $connector = CRP::Model::Schema::build_connector($app->config->{database});
    $app->helper(
        'crp.model' => sub {
            my ($c, $resultset) = @_;
            my $dbh = CRP::Model::Schema->connect(sub {return $connector->dbh});
            return $resultset ? $dbh->resultset($resultset) : $dbh;
        }
    );

    # Email address decorated with name if given
    $app->helper(
        'crp.email_decorated' => sub {
            my $c = shift;
            my($email, $name) = @_;

            $email = " <$email>" if $name;
            return ($name // '') . $email;
        }
    );

    # Email address to send email to
    $app->helper(
        'crp.email_to' => sub {
            my $c = shift;
            my($email, $name) = @_;

            $name ||= '';
            if($c->app->mode eq 'development') {
                $name .= " (Was to: $email)";
                $email = $c->app->config->{test}->{email};
            }
            return $c->crp->email_decorated($email, $name);
        }
    );

    # Trimmed CGI parameter
    $app->helper(
        'crp.trimmed_param' => sub {
            my $c = shift;
            my($param) = @_;

            my $value = $c->param($param);
            $value =~ s{^\s+|\s+$}{}g if defined $value;
            return $value;
        }
    );

    # Absolute path to public file
    $app->helper(
        'crp.path_for_public_file' => sub {
            my $c = shift;

            my($path) = @_;
            return $c->app->home->rel_file("public/$path");
        }
    );

    # Instructor photo file location within public files
    $app->helper(
        'crp.instructor_photo_location' => sub {
            return '/images/Instructors/photos/';
        }
    );

    # Name of an instructor's photo file
    $app->helper(
        'crp.name_for_instructor_photo' => sub {
            my $c = shift;

            my($id) = @_;
            return CRP::Util::WordNumber::encode_number($id) . '.jpg';
        }
    );

    # Instructor photo file path
    $app->helper(
        'crp.path_for_instructor_photo' => sub {
            my $c = shift;

            my($id) = @_;
            return $c->crp->path_for_public_file($c->crp->instructor_photo_location . $c->crp->name_for_instructor_photo($id));
        }
    );

    # Instructor photo URL
    $app->helper(
        'crp.url_for_instructor_photo' => sub {
            my $c = shift;

            my($id) = @_;
            my $name = $c->crp->name_for_instructor_photo($id);
            $name = 'default.jpg' unless -r $c->crp->path_for_public_file($c->crp->instructor_photo_location . $name);
            return $c->url_for($c->crp->instructor_photo_location . $name);
        }
    );

    # Logged-in instructor ID or 0
    $app->helper(
        'crp.logged_in_instructor_id' => sub {
            my $c = shift;

            return $c->stash('crp_session')->variable('instructor_id') || 0;
        }
    );
}

1;

