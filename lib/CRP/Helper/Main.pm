package CRP::Helper::Main;
use Mojo::Base 'Mojolicious::Plugin';

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
            $dbh->storage->sql_maker->quote_char('"');
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

    # CGI parameter as number
    $app->helper(
        'crp.numeric_param' => sub {
            my $c = shift;
            my($param) = @_;

            my $value = $c->param($param) // '';
            $value =~ s{^\s+|\s+$}{}g;
            $value = 0 unless $value =~ /^\d{1,9}$/;
            return $value;
        }
    );

    # Absolute path to public file
    $app->helper(
        'crp.path_for_public_file' => sub {
            my $c = shift;

            my($path) = @_;
            return $c->app->home->rel_file("public/$path")->to_string;
        }
    );

    # Instructor photo file location within public files
    $app->helper(
        'crp.instructor_photo_location' => sub {
            return 'images/Instructors/photos/';
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
            my $path = '/'. $c->crp->instructor_photo_location;
            return $c->crp->path_for_public_file($path . $c->crp->name_for_instructor_photo($id));
        }
    );

    # Instructor photo URL
    $app->helper(
        'crp.url_for_instructor_photo' => sub {
            my $c = shift;

            my($id) = @_;
            my $path = '/'. $c->crp->instructor_photo_location;
            my $name = $c->crp->name_for_instructor_photo($id);
            $name = 'default.jpg' unless -r $c->crp->path_for_public_file("$path$name");
            return $c->url_for("$path$name");
        }
    );

    # Instructor photo URL with cachebuster
    $app->helper(
        'crp.cachebuster_url_for_instructor_photo' => sub {
            my $c = shift;

            my($id) = @_;
            my $path = $c->crp->instructor_photo_location;
            my $name = $c->crp->name_for_instructor_photo($id);
            $name = 'default.jpg' unless -r $c->crp->path_for_public_file("$path$name");
            my $cachebuster = CRP::Util::WordNumber::encode_number(time % 100_000);
            return $c->url_for('crp.fresh', cachebuster => $cachebuster, path => "$path$name");
        }
    );

    # Logged-in instructor ID or 0
    $app->helper(
        'crp.logged_in_instructor_id' => sub {
            my $c = shift;

            return 0 unless  $c->stash('crp_session');
            return $c->stash('crp_session')->variable('instructor_id') || 0;
        }
    );

    # Format a date using one of the named formats in the config
    $app->helper(
        'crp.format_date' => sub {
            my $c = shift;
            my($date, $format_name) = @_;

            return '' unless $date;
            my $format = $app->config->{date_format}->{$format_name} || '%d%b%Y';
            return $date->strftime($format);
        }
    );

    $app->helper(
        'crp.load_profile' => sub {
            my $c = shift;

            my $instructor_id = $c->crp->logged_in_instructor_id or die "Not logged in";
            my $profile = $c->crp->model('Profile')->find_or_create({instructor_id => $instructor_id});
            $c->stash('profile_record', $profile);
            return $profile;
        }
    );

    $app->helper(
        'crp.number_or_null' => sub {
            my $c = shift;
            my($number) = @_;

            $number = undef unless defined $number && $number =~ m{^-?\d+\.?\d*$};
            return $number;
        }
    );

    $app->helper(
        'crp.stash_recaptcha' => sub {
            my $c = shift;

            $c->stash('recaptcha', $c->recaptcha_get_html) if $app->config->{recaptcha}->{secretkey};
        }
    );

    $app->helper(
        'crp.validate_recaptcha' => sub {
            my $c = shift;
            my($validation) = @_;

            if($app->config->{recaptcha}->{secretkey}) {
                $validation->error(recaptcha => ['recaptcha_fail']) unless $c->recaptcha_verify;
            }
        }
    );

    our $debug_start_time = 0;
    our $debug_last_time = 0;
    $app->helper(
        'crp.debug' => sub {
            my $c = shift;

            return if $c->app->mode eq 'production';
            require Time::HiRes;
            my $time = Time::HiRes::time();
            if( ! @_) {
                push @_, 'TIMER RESET';
                $debug_start_time = 0;
            }
            $debug_start_time = $debug_last_time = $time if $debug_start_time == 0;

            my $message = '';
            require Data::Dumper;
            {
                no warnings 'once';
                local $Data::Dumper::Indent = 0;
                local $Data::Dumper::Terse = 1;
                $message .= ' ' . Data::Dumper::Dumper(\@_);
            }

            $message = sprintf "DEBUG: %7.4f %7.4f %s\n", $time - $debug_start_time, $time - $debug_last_time, $message;
            warn $message;

            $debug_last_time = $time;
        }
    );

}

1;

