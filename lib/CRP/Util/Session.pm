package CRP::Util::Session;
use Moose;

use Mojo::JSON qw(decode_json encode_json);
use DateTime;

has _mojo           => ( is => 'ro', isa => 'Mojolicious::Controller', init_arg => 'mojo');

has _id             => ( is => 'rw', isa => 'Int', default => 0, init_arg => undef);
has expired         => ( is => 'ro', isa => 'Bool', writer => '_set_expired', default => 1, init_arg => undef);
has instructor_id   => ( is => 'rw', isa => 'Int', default => 0, init_arg => undef);
has _data           => ( is => 'ro', isa => 'HashRef', default => sub { {} }, init_arg => undef);


sub BUILD {
    my $self = shift;
    my $c = $self->_mojo;

    if($c->cookie($c->config->{session}->{cookie_name})) {
        my $mojo_session = $c->session;
    }
}

sub create_new {
    my $self = shift;

    $self->clear;
    my $c = $self->_mojo;
    my $row = $c->crp->model('Session')->create({});
    $self->_id($row->id);
    $c->session->{id} = $row->id;
    $c->session->{auto_login_id} = 0;
    $c->session(expiration => 0);
    $c->session(expires => $c->config->{session}->{default_expiry} || 3600);
}

sub DEMOLISH {
    my $self = shift;
   
warn "DEMOLISH";
    if($self->_id) {
warn "DEMOLISH: ",$self->_id;
        $self->_mojo->crp->model('Session')->find($self->_id)->update(
            {
                instructor_id       => $self->instructor_id,
                last_access_date    => DateTime->now,
                data                => encode_json($self->_data),
            }
        );
    }
}

sub variable {
    my $self = shift;
    my $variable = shift;

    if(@_) {
        my $value = shift;

        if(defined $value) {
            $self->_data->{$variable} = $value;
        }
        else {
            delete $self->_data->{$variable};
        }
    }
    return exists $self->_data->{$variable} ? $self->_data->{$variable} : undef;
}

sub clear {
    my $self = shift;

    $self->_delete_record;
    $self->_set_expired(1);
    $self->_id(0);
    my $c = $self->_mojo;
    $c->session->{id} = 0;
    $c->session->{auto_login_id} = 0;
    $c->session(expiration => 0);
    $c->session(expires => 1);
}

sub _delete_record {
    my $self = shift;

    if($self->_id) {
        $self->_mojo->crp->model('Session')->find($self->_id)->delete;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

