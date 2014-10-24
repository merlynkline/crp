package CRP::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';
use DateTime;
use Try::Tiny;
use CRP::Util:Wordnumber;

sub welcome {
    my $c = shift;

    $c->render;
}

sub page {
    my $c = shift;

    my $page = shift // $c->stash('page');

    $c->render(template => "main/pages/$page");
}

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
        notify_new_courses  => $c->param('notify'),
        notify_tutors       => $c->param('tell_tutors'),
        send_newsletter     => $c->param('newsletter'),
    };
    my $error;
    my $new_record;
    try {
        $new_record = $c->crp_model('Enquiry')->create($record);
    }
    catch {
        warn "Adding new enquiry: $_";
        $validation->error(_general => ['create_record']);
    };
    return $c->page('carers') if($validation->has_error);

    my $identifier = CRP::Util:Wordnumber::encode_number($new_record->{id});
    $c->mail(
        to          => $new_record->{email},
        template    => 'main/email/enquiry_confirmation',
    );

    $c->redirect_to('/page/registered');
}

sub _number_or_null {
    my($number) = @_;

    $number = undef unless $number =~ m{^-?\d+\.?\d*$};
    return $number;
}

1;
