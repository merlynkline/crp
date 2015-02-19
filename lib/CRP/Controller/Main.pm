package CRP::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;
use DateTime;
use Try::Tiny;
use CRP::Util::WordNumber;
use CRP::Util::Session;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');
    $c->stash('page', $page);

    $c->render(template => "main/pages/$page", @_);
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
        to          => $c->crp->email_to($c->app->config->{email_addresses}->{contact_form}),
        template    => 'main/email/contact_form',
        info        => {message => $message},
    );
    $c->redirect_to('/page/contacted');
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
        latitude            => $c->crp->number_or_null($c->param('latitude')),
        longitude           => $c->crp->number_or_null($c->param('longitude')),
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
        $record->$_($c->crp->number_or_null($c->param($_))) foreach (qw(latitude longitude));
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
sub fresh {
    my $c = shift;

    return $c->reply->static($c->stash('path'));
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub tutor_list {
    my $c = shift;

    my $tutor_list = $c->crp->model('Profile')->search_live_profiles();
    $c->stash(tutor_list => [$tutor_list->all]);
    return $c->page('tutor_list');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub instructor_search {
    my $c = shift;

    my $matches;
    if($c->req->method eq 'POST') {
        my $validation = $c->validation;
        $validation->required('name');
        my $name = $c->crp->trimmed_param('name');
        $name =~ s{^ [%\s]+ | [\s%]+ $}{}gsmx; # Prevent match-all searches
        $validation->error(name => ['like']) unless $name;
        if( ! $validation->has_error) {
            if($name =~ m{^-?(\d+)$}) {
                return $c->redirect_to('crp.membersite.certificate', slug => "-$1");
            }
            else {
                $c->stash(search_key => $name);
                $matches = $c->_find_instructors($name);
                if($matches && @$matches == 1) {
                    return $c->redirect_to('crp.membersite.home', slug => $matches->[0]->web_page_slug);
                }
            }
        }
    }
    return $c->page('instructor_search', matches => $matches);
}

sub _find_instructors {
    my $c = shift;
    my($search_key) = @_;

    my @matches = $c->crp->model('Profile')->search_live_profiles(
        {'lower(name)' => { like => lc "%$search_key%"}},
        {order_by => {-asc => 'lower(name)'}},
    );
    return \@matches if @matches;
    return;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub location_search {
    my $c = shift;

    my $latitude  = $c->crp->number_or_null($c->param('latitude'));
    my $longitude = $c->crp->number_or_null($c->param('longitude'));

    if($latitude && $longitude) {
        my @courses_list = $c->crp->model('Course')->search_near_location(
            DateTime->now()->subtract(days => $c->config->{course}->{'age_when_advert_expires_days'}),
            $latitude,
            $longitude,
            $c->config->{'instructor_search_distance'},
            {},
            { order_by => {-asc => 'start_date'} },
        );

        my @instructors_list = $c->crp->model('Profile')->search_near_location(
            $latitude,
            $longitude,
            $c->config->{'instructor_search_distance'},
            {},
            { order_by => {-asc => 'lower(name)'} },
        );

        $c->stash(instructors_list => \@instructors_list);
        $c->stash(courses_list => \@courses_list);
    }
    else {
        return $c->redirect_to('crp.page', page => 'location_search');
    }
    $c->render(template => 'main/location_search_results');
}

1;

