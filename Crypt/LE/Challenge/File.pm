package Crypt::LE::Challenge::File;
use strict;
use warnings;

use Carp;
use File::Path qw(make_path);

our $VERSION = '0.10';

=head1 NAME

Crypt::LE::Challenge::File - A simple file-based challenge handler for Crypt::LE and Crypt::LE client
application (le.pl) with challenge/verification handlers.

Based on Crypt::LE::Challenge::Simple

=head1 SYNOPSIS

 use Crypt::LE;
 use Crypt::LE::Challenge::File;
 ...
 my $le = Crypt::LE->new();
 my $file_challenge = Crypt::LE::Challenge::File->new();
 ..
 $le->accept_challenge($file_challenge, {public_doc_path => "/var/www"});
 $le->verify_challenge($file_challenge, {public_doc_path => "/var/www"});

=head1 DESCRIPTION

Crypt::LE provides the functionality necessary to use Let's Encrypt API and generate free SSL certificates for your domains.
This Crypt::LE plugin is an example of how challenge and verification handling can be done by an external module.

B<This module can also be used with the provided Crypt::LE client application - le.pl:>

 le.pl ... --handle-with Crypt::LE::Challenge::File --handle-params '{"public_doc_path": "/var/www"}'

=cut

sub new { bless {}, shift }
 
sub handle_challenge_http {
    my $self = shift;
    my ($challenge, $params) = @_;

    my $path = _get_path_from_params($params);
    make_path($path);
    open my $challenge_fh, '>', "$path/$challenge->{token}" or _fatal("Could not write file '$path/$challenge->{token}': $!");
    print $challenge_fh "$challenge->{token}.$challenge->{fingerprint}";
    close $challenge_fh;
    return 1;
};

sub handle_challenge_tls {
    # Return 0 to indicate an error
    return 0;
}

sub handle_challenge_dns {
    # Critical error will be treated as a failure too
    die "Oh, this challenge is not supported!\n";
}

sub handle_verification_http {
    my $self = shift;
    my ($verification, $params) = @_;

    my $path = _get_path_from_params($params);
    print "Domain $verification->{domain} " . ($verification->{valid} ? "has been verified successfully." : "has NOT been verified.") . "\n";
    unlink "$path/$verification->{token}";
    return 1;
}

sub _get_path_from_params {
    my($params) = @_;

    _fatal("public_doc_path parameter required\n") unless $params->{public_doc_path};
    my $path = $params->{public_doc_path};
    $path .= "/.well-known/acme-challenge";
    return $path;
}

sub _fatal {
    my($message) = @_;

    print "FATAL: $message\n";
    croak $message;
}



sub handle_verification_tls {
    1;
}

sub handle_verification_dns {
    1;
}

=head1 AUTHOR

Merlyn Kline, C<< <MERLYNK at cpan.org> >>

=cut

1;
