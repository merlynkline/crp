package CRP::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;
use DateTime;
use Try::Tiny;
use CRP::Util::WordNumber;
use CRP::Util::Session;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    $c->render;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');
    $c->stash('page', $page);

    $c->render(template => "main/pages/$page");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub contact {
    my $c = shift;

    my $validation = $c->validation;
    $validation->required('email')->like(qr{^.+@.+[.].+});
    $validation->required('message');
    return $c->page('contact') if($validation->has_error);

    my $message = Mojo::Util::xml_escape($c->param('message'));
    $message =~ s{\n}{<br \\>\n}g;
    $c->mail(
        from        => $c->crp->email_decorated($c->crp->trimmed_param('email'), $c->crp->trimmed_param('name')),
        to          => $c->crp->email_to($c->app->config->{contact}->{to}),
        template    => 'main/email/contact_form',
        info        => {message => $message},
    );
    $c->redirect_to($c->url_for('/page/contacted'));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub register_interest {
    my $c = shift;

    my $validation = $c->validation;
    $validation->required('email')->like(qr{^.+@.+[.].+});
    return $c->page('enquiry') if($validation->has_error);
    my $record = {
        name                => $c->crp->trimmed_param('name'),
        email               => $c->crp->trimmed_param('email'),
        suspend_date        => DateTime->now(),
        location            => $c->crp->trimmed_param('location'),
        latitude            => _number_or_null($c->param('latitude')),
        longitude           => _number_or_null($c->param('longitude')),
        notify_new_courses  => 1,
        notify_tutors       => $c->param('tell_tutors'),
        send_newsletter     => $c->param('newsletter'),
    };
    my $new_record;
    if($c->_case_insensitive_enquiry_email_find($record->{email})) {
        $validation->error(email => ['duplicate_email']);
    }
    else {
        try {
            # DBIx::Class::ResultSet::create apparently doesn't call our custom accessors so
            # use new_result and then call the accessors, then insert the new record.
            my $row = $c->crp->model('Enquiry')->new_result($record);
            foreach my $column (keys %$record) {
                $row->$column($record->{$column});
            }
            $new_record = $row->insert;
        }
        catch {
            if(m{duplicate key .+enquiry_email}) {
                $validation->error(email => ['duplicate_email']);
            }
            else {
                $validation->error(_general => ['create_record']);
            }
        };
    }
    return $c->page('enquiry') if($validation->has_error);

    $c->_send_confirmation_email($new_record->id, $record);

    $c->redirect_to($c->url_for('/page/registered')->query(email => $record->{email}));

    $c->_enquiry_housekeeping();
}

sub _number_or_null {
    my($number) = @_;

    $number = undef unless $number =~ m{^-?\d+\.?\d*$};
    return $number;
}

sub _send_confirmation_email {
    my $c = shift;
    my($id, $record) = @_;

    my $identifier = CRP::Util::WordNumber::encode_number($id);
    my $email_info = {
        identifier              => $identifier,
        confirm_page            => $c->url_for('/update_registration')->query(id => $identifier)->to_abs(),
        general_confirm_page    => $c->url_for('/update_registration')->to_abs(),
    };
    $email_info->{$_} = $record->{$_} foreach(qw(
        location notify_new_courses notify_tutors send_newsletter name
    ));
    $c->mail(
        to          => $c->crp->email_to(@$record{qw(email name)}),
        template    => 'main/email/enquiry_confirmation',
        info        => $email_info,
    );
}

sub _case_insensitive_enquiry_email_find {
    my $c = shift;
    my($email) = @_;

    return $c->crp->model('Enquiry')->find({'lower(me.email)' => lc $email});
}

sub _enquiry_housekeeping {
    my $c = shift;

    my $days = $c->app->config->{enquiry}->{max_suspended_period_days} || 30;
    my $dtf = $c->crp->model('Enquiry')->result_source->schema->storage->datetime_parser;
    $c->crp->model('Enquiry')->search(
        { suspend_date => {'<', $dtf->format_datetime(DateTime->now()->subtract(days => $days))} }
    )->delete;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub resend_confirmation {
    my $c = shift;

    my $email = $c->param('email');
    return $c->redirect_to('/') unless $email;

    my $record = $c->_case_insensitive_enquiry_email_find($email);
    $c->_send_confirmation_email($record->id, {$record->get_inflated_columns}) if($record);

    return $c->page('registered');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub update_registration {
    my $c = shift;

    my $confirmation_code = $c->param('id');

    my $record;
    if($confirmation_code) {
        my $id = CRP::Util::WordNumber::decode_number($confirmation_code);
        $record = $c->crp->model('Enquiry')->find({id => $id}) if $id && length $id < 10;
    }
    return $c->render(template => "main/update_registration_retry") unless $record;

    if($record->suspend_date()) {
        $record->suspend_date(undef);
        $c->stash(confirmed => 1);
    }

    if($c->param('do_update')) {
        $record->$_($c->crp->trimmed_param($_)) foreach (qw(
            name location notify_new_courses notify_tutors send_newsletter
        ));
        $record->$_(_number_or_null($c->param($_))) foreach (qw(latitude longitude));
        $c->stash(updated => 1);
    }

    $record->update();

    $c->stash(email => $record->email());
    $c->stash(confirmation_code => $confirmation_code);
    $c->param($_, $record->$_()) foreach(qw(name location));
    $c->param($_, $record->$_() ? 'Y' : '') foreach(qw(notify_new_courses notify_tutors send_newsletter));
    $c->render(template => "main/update_registration");

    $c->_enquiry_housekeeping();
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub login {
    my $c = shift;

    my $email       = $c->crp->trimmed_param('email');
    my $password    = $c->crp->trimmed_param('password');
    my $auto_login  = $c->param('auto_login');
    my $forgotten   = $c->param('forgotten');

    my $validation = $c->validation;
    $validation->required('email')->like(qr{^.+@.+[.].+});
    my $login_record = $c->_case_insensitive_login_email_find($email);
    $validation->error(email => ['no_such_email']) unless $login_record;
    return $c->page('login') if($validation->has_error);

    return $c->_send_otp($login_record) if $forgotten;

    $validation->required('password');
    unless($validation->has_error) {
#TODO: validate the password here
        $validation->error(password => ['incorrect_password']);
        sleep 3;
    }
    return $c->page('login') if $validation->has_error;

#TODO: Handle actual login logic
    die "eeek";
}

sub _case_insensitive_login_email_find {
    my $c = shift;
    my($email) = @_;

    return $c->crp->model('Login')->find({'lower(me.email)' => lc $email});
}

sub _send_otp {
    my $c = shift;
    my($login_record) = @_;

    my $identifier = CRP::Util::WordNumber::encode_number($login_record->id);
    my $otp = unpack "H32", Mojo::Util::md5_bytes CRP::Util::WordNumber::encode_number(int rand() * 100000);
    my $hours = $c->app->config->{login}->{otp_lifetime};
    my $email_info = {
        identifier          => "$identifier/$otp",
        otp_page            => $c->url_for("/otp/$identifier/$otp")->to_abs(),
        general_otp_page    => $c->url_for('/otp')->to_abs(),
        lifetime            => $hours,
    };
    $c->mail(
        to          => $c->crp->email_to($login_record->email),
        template    => 'main/email/otp',
        info        => $email_info,
    );

    $login_record->otp_expiry_date(DateTime->now()->add(hours => $hours));
    $login_record->otp_hash($otp);
    $login_record->update();

    $c->redirect_to($c->url_for('/otp')->query(email => $login_record->email));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub otp {
    my $c = shift;

    my $otp = $c->stash('otp') || $c->crp->trimmed_param('otp');
    return $c->page('otp') unless $otp;

    my $validation = $c->validation;
    $validation->error(otp => ['like']) unless $otp =~ m{[a-z0-9-]+/[a-f0-9]{32,32}}i;
    return $c->page('otp') if($validation->has_error);

    my($identifier, $hash) = split '/', $otp;
    my $id = CRP::Util::WordNumber::decode_number($identifier);
    my $login_record = $c->crp->model('Login')->find($id);
    unless($login_record
      && ($login_record->otp_hash // '') eq $hash
      && $login_record->otp_expiry_date > DateTime->now) {
        $validation->error(otp => ['incorrect_password']);
        sleep 3;
    }
    return $c->page('otp') if($validation->has_error);
    
    $login_record->otp_expiry_date(undef);
    $login_record->otp_hash(undef);
    $login_record->update();

    $c->_do_login($login_record->id);
    $c->redirect_to($c->url_for('logged_in_default'));
}

sub _do_login {
    my $c = shift;
    my($instructor_id) = @_;

    my $crp_session = $c->stash('crp_session');
    $crp_session->create_new($c);
    $crp_session->variable($c, instructor_id => $instructor_id);
}

1;
