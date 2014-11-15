package CRP::Helper::Main;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

sub register {
    my $self = shift;
    my($app) = @_;

    # Get a value from the stash, always returning a listref
    $app->helper(
        'crp.stash_list' => sub {
            my $self = shift;
            my $var_value = $self->stash($_[0]);
            return [] unless $var_value;
            $var_value = [ $var_value ] unless ref $var_value;
            return $var_value;
        }
    );

    # database connection prefork-safe with DBIx::Connector
    my $connector = CRP::Model::Schema::build_connector($app->config->{database});
    $app->helper(
        'crp.model' => sub {
            my ($self, $resultset) = @_;
            my $dbh = CRP::Model::Schema->connect(sub {return $connector->dbh});
            return $resultset ? $dbh->resultset($resultset) : $dbh;
        }
    );

    # Email address decorated with name if given
    $app->helper(
        'crp.email_decorated' => sub {
            my $self = shift;
            my($email, $name) = @_;

            $email = " <$email>" if $name;
            return "$name$email";
        }
    );

    # Email address to send email to
    $app->helper(
        'crp.email_to' => sub {
            my $self = shift;
            my($email, $name) = @_;

            $name ||= '';
            if($self->app->mode eq 'development') {
                $name .= " (Was to: $email)";
                $email = $self->app->config->{test}->{email};
            }
            return $self->crp->email_decorated($email, $name);
        }
    );

    # Trimmed CGI parameter
    $app->helper(
        'crp.trimmed_param' => sub {
            my $self = shift;
            my($param) = @_;

            my $value = $self->param($param);
            $value =~ s{^\s+|\s+$}{}g if defined $value;
            return $value;
        }
    );


}

1;

