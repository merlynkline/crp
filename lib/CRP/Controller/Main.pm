package CRP::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';
use DateTime;
use Try::Tiny;
use CRP::Util::WordNumber;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub welcome {
    my $c = shift;

    $c->render;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');

    $c->render(template => "main/pages/$page");
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub register_interest {
    my $c = shift;

    my $validation = $c->validation;
    $validation->required('email')->like(qr{^.+@.+[.].+});
    return $c->page('carers') if($validation->has_error);
    my $record = {
        name                => $c->param('name'),
        email               => $c->param('email'),
        suspend_date        => DateTime->now(),
        location            => $c->param('location'),
        latitude            => _number_or_null($c->param('latitude')),
        longitude           => _number_or_null($c->param('longitude')),
        notify_new_courses  => 1,
        notify_tutors       => $c->param('tell_tutors'),
        send_newsletter     => $c->param('newsletter'),
    };
    my $error;
    my $new_record;
    try {
        # DBIx::Class::ResultSet::create apparently doesn't call our custom accessors so
        # use new_result and then call the accessors, then insert the new record.
        my $row = $c->crp_model('Enquiry')->new_result($record);
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
            warn "Adding new enquiry: $_";
            $validation->error(_general => ['create_record']);
        }
    };
    return $c->page('carers') if($validation->has_error);

    $c->_send_confirmation_email($new_record->id, $record);

    $c->redirect_to($c->url_for('/page/registered')->query(email => $record->{email}));
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
        to          => $c->crp_email_to(@$record{qw(email name)}),
        template    => 'main/email/enquiry_confirmation',
        info        => $email_info,
    );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub resend_confirmation {
    my($c) = @_;

    my $email = $c->param('email');
    return $c->redirect_to('/') unless $email;

    my $record = $c->crp_model('Enquiry')->find({email => $email});
    $c->_send_confirmation_email($record->id, {$record->get_inflated_columns}) if($record);

    return $c->page('registered');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub update_registration {
    my($c) = @_;

    my $confirmation_code = $c->param('id');

    my $record;
    if($confirmation_code) {
        my $id = CRP::Util::WordNumber::decode_number($confirmation_code);
        $record = $c->crp_model('Enquiry')->find({id => $id}) if $id && length $id < 10;
    }
    return $c->render(template => "main/update_registration_retry") unless $record;

    if($record->suspend_date()) {
        $record->suspend_date(undef);
        $c->stash(confirmed => 1);
    }

    if($c->param('do_update')) {
        $record->$_($c->param($_)) foreach (qw(name location notify_new_courses notify_tutors send_newsletter));
        $record->$_(_number_or_null($c->param($_))) foreach (qw(latitude longitude));
        $c->stash(updated => 1);
    }

    $record->update();

    $c->stash(email => $record->email());
    $c->stash(confirmation_code => $confirmation_code);
    $c->param($_, $record->$_()) foreach(qw(name location));
    $c->param($_, $record->$_() ? 'Y' : '') foreach(qw(notify_new_courses notify_tutors send_newsletter));
    $c->render(template => "main/update_registration");
}

1;
