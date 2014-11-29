package CRP::Util::Session;
use Moose;

use Carp;
use Mojo::JSON qw(decode_json encode_json);
use DateTime;

has _mojo           => ( is => 'rw', isa => 'Mojolicious::Controller', init_arg => 'mojo');
has _id             => ( is => 'rw', isa => 'Int', default => 0, init_arg => undef);
has expired         => ( is => 'ro', isa => 'Bool', writer => '_set_expired', default => 1, init_arg => undef);
has _data           => ( is => 'rw', isa => 'HashRef', default => sub { {} }, init_arg => undef);
has _loaded         => ( is => 'rw', isa => 'Bool', default => 0, init_arg => undef);
has _dirty          => ( is => 'rw', isa => 'Bool', default => 0, init_arg => undef);

my %_COOKIE_SESSION_VARIABLE = (
    instructor_id   => 1,
    auto_login_id   => 1,
    email           => 1,
);


sub _load_or_create {
    my $self = shift;

    $self->_debug('_load_or_create: loaded=' . ($self->_loaded ? 'Y' : 'N'));
    return if $self->_loaded;
    my $c = $self->_mojo;
    my $row;
    if($c->session('id')) {
        $row = $c->crp->model('Session')->find_or_create({id => $c->session('id')});
    }
    else {
        $row = $c->crp->model('Session')->create({});
    }
    $self->_id($row->id);
    $c->session(id => $row->id);
    $self->_data($row->data ? decode_json($row->data) : {});
    $self->_loaded(1);
    $self->_dirty(0);
    $self->_debug('_load_or_create: done: id=' . $row->id);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub create_new {
    my $self = shift;
    $self->_debug('create_new: ' . ref $_[0]);

    $self->_debug('create_new');
    my $c = $self->_mojo;
    $self->clear($c);
    my $row = $c->crp->model('Session')->create({});
    $self->_id($row->id);
    $self->_loaded(1);
    $c->session(id => $row->id);
    $c->session(auto_login_id => 0);
    $c->session(expires => time + ($c->config->{session}->{default_expiry} || 3600));
    $c->session(last_access => time);
    $self->_debug('create_new: done: id=' . $row->id);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub write {
    my $self = shift;
   
    $self->_debug('write: dirty=' . ($self->_dirty ? 'Y' : 'N') . ', loaded=' . ($self->_loaded ? 'Y' : 'N'));
    return unless $self->_dirty;
    if($self->_loaded && $self->_dirty) {
        $self->_mojo->crp->model('Session')->find($self->_id)->update(
            {
                last_access_date    => DateTime->now,
                data                => encode_json($self->_data),
            }
        );
    }
    $self->_dirty(0);
    $self->_debug('write: done');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub variable {
    my $self = shift;
    my $variable = shift;

    $self->_debug("variable: var=$variable, set = " . (@_ ? 'Y' : 'N'));
    my $value;
    if($_COOKIE_SESSION_VARIABLE{$variable}) {
        $value = $self->_cookie_session_variable($variable, @_);
    }
    else {
        $value = $self->_db_session_variable($variable, @_);
    }
    $self->_mojo->session(last_access => time);
    $self->_debug('variable: done: ' . (defined $ value ? $value : '<UNDEF>'));
    return $value;
}

sub _db_session_variable {
    my $self = shift;
    my $variable = shift;

    $self->_debug("_db_session_variable: var=$variable ");
    $self->_load_or_create;
    if(@_) {
        my $value = shift;

        if(defined $value) {
            $self->_dirty(
                ! exists $self->_data->{$variable}
                || ref $self->_data->{$variable}
                || ref $value
                || $value ne $self->_data->{$variable}
            );
            $self->_data->{$variable} = $value;
        }
        else {
            $self->_dirty(exists $self->_data->{$variable});
            delete $self->_data->{$variable};
        }
    }
    return exists $self->_data->{$variable} ? $self->_data->{$variable} : undef;
}

sub _cookie_session_variable {
    my $self = shift;
    my $variable = shift;

    my $c = $self->_mojo;
    if(@_) {
        $c->session($variable => shift);
        return $c->session($variable) // undef;
    }
    return $c->session($variable) // undef if $c->cookie($c->config->{session}->{cookie_name});
    return undef;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub clear {
    my $self = shift;

    $self->_debug("clear");
    $self->_mojo->crp->model('Session')->find($self->_id)->delete if $self->_id;
    $self->_set_expired(1);
    $self->_id(0);
    my $c = $self->_mojo;
    $c->session(id => 0);
    my $expiry_time = 1;
    if($c->session('auto_login_id')) {
        $expiry_time = time + ($c->config->{session}->{default_expiry} || 3600 * 24 * 7 * 4);
    }
    $c->session(expires => $expiry_time);
    $c->session(last_access => time);
    $self->_loaded(0);
    $self->_dirty(0);
}

sub _debug {
    my $self = shift;

    # warn @_;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

