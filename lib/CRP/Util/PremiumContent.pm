package CRP::Util::PremiumContent;

use Moose;

use Carp;
use IO::Dir;
use Mojo::Util qw(b64_decode b64_encode);
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Date;

use constant {
    DEFAULT_PAGE   => 'welcome',
    WELCOME_MAIL   => 'welcome',
    ACCESS_PAGE    => 'access',
    STATIC_CONTENT => 'static',
    STREAM_CONTENT => 'stream',
    PREMIUM_PATH   => 'premium',
    PAGE_PATH      => 'templates',
    STATIC_PATH    => 'static',
    STREAM_PATH    => 'stream',
};

has c    => (is => 'ro', required => 1);
has id   => (is => 'ro', required => 1);
has dir  => (is => 'ro', required => 1);
has path => (is => 'ro', required => 1);

has cookie  => (is => 'ro', isa => 'Maybe[HashRef]', init_arg => undef, lazy => 1, builder => '_build_cookie', writer => '_set_cookie');


sub paths {
    my($c) = @_;

    my @paths;
    my $base_dir = $c->app->home->rel_file(PREMIUM_PATH);

    my $dir = IO::Dir->new($base_dir);
    while(defined(my $entry = $dir->read)) {
        my $sub_dir = "$base_dir/$entry/" . PAGE_PATH;
        if(-d $sub_dir) {
            push @paths, $entry if
                -f "$sub_dir/" . DEFAULT_PAGE . '.html.ep'
                and -f "$sub_dir/" . ACCESS_PAGE . '.html.ep'
                and -f "$sub_dir/" . WELCOME_MAIL . '.mail.ep'
            ;
        }
    }

    return \@paths;
}


sub id_from_email_and_dir {
    my($c, $email, $dir) = @_;

    my $auth_record = $c->crp->model('PremiumAuthorisation')->find(
        {'lower(me.email)' => lc $email},
        {directory         => $dir},
    );

    return $auth_record ? $auth_record->id : 0;
}


sub create_authorisation {
    my($c, $email, $dir, $name) = @_;

    $c->crp->model('PremiumAuthorisation')->create({
            email       => $email,
            name        => $name,
            directory   => $dir,
            is_disabled => 0,
        });

    my $id = _id_as_symbol(id_from_email_and_dir($c, $email, $dir));
    my $template = join '/', $dir, PAGE_PATH, WELCOME_MAIL;
    my $info = {
        email   => $email,
        name    => $name,
        dir     => $dir,
        id      => $id,
    };
    _send_email($c, $email, $template, $dir, $info);
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


sub is_authorised_id {
    my $self = shift;

    return $self->id eq $self->authorised_id;
}


sub cookie_id_matches {
    my $self = shift;

    return $self->cookie && $self->cookie->{id} == $self->_numeric_id;
}


sub _numeric_id {
    my $self = shift;

    my $id = $self->id;
    $id = CRP::Util::WordNumber::decode_number($id) if $id !~ /^\d+$/;
    return $id if $id > 0 && $id < 2_000_000_000;
    return 0;
}


sub _id_as_symbol {
    my($id) = @_;

    $id = CRP::Util::WordNumber::encode_number($id) if $id =~ /^\d+$/ && $id > 0 && $id < 2_000_000_000;
    return $id;
}


sub cookie_dir_matches {
    my $self = shift;

    return $self->cookie && $self->cookie->{dir} eq $self->dir;
}


sub authorised_id {
    my $self = shift;

    return $self->c->config->{premium}->{authorised_id};
}


sub  _build_cookie {
    my $self = shift;

    return unless my $cookie = $self->c->signed_cookie($self->c->config->{premium}->{cookie_name});
    $cookie = $self->_deserialise_cookie($cookie);
    return {
        id      => $cookie->[0],
        dir     => $cookie->[1],
        name    => $cookie->[2],
        email   => $cookie->[3],
        expires => $cookie->[4],
    };
}


sub _deserialise_cookie {
    my $self = shift;

    my($data) = @_;
    $data =~ s/-/=/g;
    $data = b64_decode($data);
    $data = decode_json($data);
    return $data;
}


sub _serialise_cookie {
    my $self = shift;

    my $cookie = $self->cookie;
    croak "Cookie data not set" unless $cookie;
    my $value = encode_json([@$cookie{qw(id dir name email expires)}]);
    $value = b64_encode($value, '');
    $value =~ s/=/-/g;
    return $value;
}


sub cookie_expired {
    my $self = shift;

    return $self->cookie && $self->cookie->{expires} < time;
}


sub generate_cookie {
    my $self = shift;

    my $cookie;
    my $authorisation = $self->c->crp->model('PremiumAuthorisation')->find($self->_numeric_id) if $self->_numeric_id;
    if($authorisation && ! $authorisation->is_disabled) {
        $cookie = {
            id      => $self->_numeric_id,
            dir     => $authorisation->directory,
            name    => $authorisation->name,
            email   => $authorisation->email,
            expires => time + $self->c->config->{premium}->{expiry},
        };

        $self->c->crp->model('PremiumCookieLog')->create({
                auth_id     => $self->_numeric_id,
                remote_id   => $self->_remote_id,
            });
    }

    $self->_set_cookie($cookie);
}


sub _remote_id {
    my $self = shift;

    return '1'
    . ':' . ($self->c->req->headers->header('X-Real-IP') || '')
    . ':' . ($self->c->tx->remote_address || '')
    . ':' . ($self->c->req->headers->header('X-Forwarded-For') || '')
    ;
}


sub _set_response_cookie {
    my $self = shift;

    $self->c->signed_cookie(
        $self->c->config->{premium}->{cookie_name} => $self->_serialise_cookie,
        {
            path    => $self->c->config->{premium}->{root} . '/' . $self->cookie->{dir},
            expires => time + $self->c->config->{premium}->{cookie_life},
        }
    );
}


sub redirect_to_authorised_path {
    my $self = shift;

    $self->_set_response_cookie;
    my $authorised_path = $self->c->config->{premium}->{root}
    . '/' . $self->dir
    . '/' . $self->c->config->{premium}->{authorised_id}
    . '/' . ($self->path // '')
    ;
    return $self->c->redirect_to($self->c->url_for($authorised_path));
}


sub dir_exists {
    my $self = shift;

    return -f $self->_file_path('');
}


sub content_exists {
    my $self = shift;

    return -f $self->_file_path($self->_non_blank_path);
}


sub show_not_found_page {
    my $self = shift;

    $self->c->stash(cookie => $self->cookie);
    $self->render_template('404_page', status => 404);
}


sub show_access_page {
    my $self = shift;

    $self->c->crp->stash_recaptcha();
    return $self->render_template(join '/', $self->dir, PAGE_PATH, ACCESS_PAGE);
}


sub send_content {
    my $self = shift;

    return $self->show_not_found_page unless $self->content_exists;
    $self->_set_response_cookie;
    $self->c->stash(cookie => $self->cookie);
    my $path = $self->_non_blank_path;

    return $self->_send_static_content if $self->_is_static_path;
    return $self->_send_stream_content if $self->_is_stream_path;

    $path =~ s/\.html$//;
    $self->render_template(join '/', $self->dir, PAGE_PATH, $path);
}

sub _send_static_content {
    my $self = shift;

    $self->c->reply->static('../' . $self->_rel_file_path($self->path));
}

sub _send_stream_content {
    my $self = shift;

    my $asset = $self->c->app->static->file('../' . $self->_rel_file_path($self->path));

    my $types = $self->c->app->types;
    my $type = $self->path =~ /\.(\w+)$/ ? $types->type($1) : undef;
    $self->c->res->headers->content_type($type || $types->type('txt'));

    $self->c->reply->asset($asset);
}


sub _file_path {
    my $self = shift;

    return $self->c->app->home->rel_file($self->_rel_file_path(@_));
}


sub _rel_file_path {
    my $self = shift;
    my($path) = @_;

    if($self->_is_static_path) {
        my $static_prefix = STATIC_CONTENT . '/';
        $path =~ s/$static_prefix//;
        return join '/', PREMIUM_PATH, $self->dir, STATIC_PATH, $path;
    }

    if($self->_is_stream_path) {
        my $stream_prefix = STREAM_CONTENT . '/';
        $path =~ s/$stream_prefix//;
        return join '/', PREMIUM_PATH, $self->dir, STREAM_PATH, $path;
    }

    my $file_path = $path;
    $file_path .= '.html' unless $file_path =~ /\.html$/;
    $file_path .= '.ep';

    return join '/', PREMIUM_PATH, $self->dir, PAGE_PATH, $file_path;
}


sub _is_static_path {
    my $self = shift;

    my $static_prefix = STATIC_CONTENT . '/';
    return $self->path =~ /^$static_prefix/;
}


sub _is_stream_path {
    my $self = shift;

    my $stream_prefix = STREAM_CONTENT . '/';
    return $self->path =~ /^$stream_prefix/;
}


sub render_template {
    my $self = shift;
    my($template, @params) = @_;

    my $renderer = $self->c->app->renderer;
    unshift @{$renderer->paths}, $self->c->app->home->rel_file(PREMIUM_PATH);
    unshift @{$renderer->paths}, $self->c->app->home->rel_file(join '/', PREMIUM_PATH, $self->dir, PAGE_PATH);
    $self->c->render($template, @params);
    shift @{$renderer->paths};
    shift @{$renderer->paths};
}


sub send_email {
    my $self = shift;
    my($to, $template, $info) = @_;

    _send_email($self->c, $to, $template, $self->dir, $info);
}


sub _send_email {
    my($c, $to, $template, $dir, $info) = @_;

    my $renderer = $c->app->renderer;
    unshift @{$renderer->paths}, $c->app->home->rel_file(PREMIUM_PATH);
    unshift @{$renderer->paths}, $c->app->home->rel_file(join '/', PREMIUM_PATH, $dir, PAGE_PATH);
    $c->mail(
        to          => $c->crp->email_to($to),
        template    => $template,
        info        => $info,
    );
    shift @{$renderer->paths};
    shift @{$renderer->paths};
}


sub _non_blank_path {
    my $self = shift;

    return $self->path || DEFAULT_PAGE;
}


sub get_all_pages_for_email {
    my $self = shift;
    my($email) = @_;

    my @pages = $self->c->crp->model('PremiumAuthorisation')->search({email => $email, is_disabled => 0});
    return unless @pages;

    return map { { id => _id_as_symbol($_->id), dir => $_->directory } } @pages;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

