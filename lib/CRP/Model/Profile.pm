package CRP::Util::Session;
use Moose;

use Carp;

has _mojo           => ( is => 'rw', isa => 'Mojolicious::Controller', init_arg => 'mojo');
has instructor_id   => ( is => 'rw', isa => 'int', required => 1);

has name            => ( is => 'rw', isa => '', init_arg => undef);
has address         => ( is => 'rw', isa => '', init_arg => undef);
has postcode        => ( is => 'rw', isa => '', init_arg => undef);
has telephone       => ( is => 'rw', isa => '', init_arg => undef);
has mobile          => ( is => 'rw', isa => '', init_arg => undef);
has photo           => ( is => 'rw', isa => '', init_arg => undef);
has blurb           => ( is => 'rw', isa => '', init_arg => undef);
has web_page_slug   => ( is => 'ro', isa => '', writer => '_set_web_page_slug', init_arg => undef);

has _storage        => ( is => 'rw', isa => 'CRP::Model::Schema::Result::Profile', init_arg => undef);
