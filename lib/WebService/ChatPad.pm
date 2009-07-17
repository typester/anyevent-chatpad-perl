package WebService::ChatPad;
use Any::Moose;

extends any_moose('::Object'), 'Object::Event';

use AnyEvent;
use AnyEvent::HTTP;
use HTTP::Request::Common;

our $VERSION = '0.01';

has cookie => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has endpoint => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://chatpad.jp:8080/ChatPad/',
);

no Any::Moose;

sub chat_start {
    my $self = shift;

    my $r = $self->_request( POST $self->_uri('cmd'), [ cmd => 'chat.start' ] );

    my $w; $w = http_request(
        $r->{method} => $r->{uri},
        headers      => $r->{headers},
        body         => $r->{content},
        sub {
            my ($body, $headers) = @_;
            undef $w;

            if ($body ne 'chat.start') {
                $self->event( on_error => 'Failed to start chat: ' . $body );
                return;
            }

            my ($cookie) = $headers->{'set-cookie'} =~ /(JSESSIONID=.*?);/;
            $self->cookie($cookie) if $cookie;

            $self->_poll;
        },
    );
}

sub send_message {
    my ($self, $msg) = @_;

    my $r = $self->_request( POST $self->_uri('cmd'), [ cmd => 'M', content => $msg ] );

    my $w; $w = http_post( $r->{uri}, $r->{content}, headers => $r->{headers}, sub {
        undef $w;
    });
}

sub _uri {
    my ($self, $cmd) = @_;
    $self->endpoint . $cmd;
}

sub _request {
    my ($self, $req) = @_;

    my %headers = map { $_ => $req->header($_) } $req->headers->header_field_names;
    $headers{Cookie} = $self->cookie if $self->cookie;

    return {
        method  => $req->method,
        uri     => $req->uri,
        content => $req->content,
        headers => \%headers,
    };
}

sub _poll {
    my $self = shift;

    my $r = $self->_request( GET $self->_uri('notify') );

    my $w; $w = http_request(
        $r->{method} => $r->{uri},
        headers      => $r->{headers},
        on_body      => sub {
            my ($body) = @_;

            $self->_poll_handler($body);
            undef $w;

        }, sub { undef $w },
    );
}

sub _poll_handler {
    my ($self, $body) = @_;

    if ($body eq '[wait]') {
        $self->event( on_error => '[wait] received, something wrong!' );
    }

    for my $line (split /\r?\n/, $body) {
        my ($cmd, $content) = $line =~ /^(.)(.+)$/;
        if ($cmd && $content) {
            if ($cmd eq 's') {  # system
                if ($content eq 'w') { # wait other
                    $self->event('on_chat_waiting');
                }
                elsif ($content eq 's') {
                    $self->event('on_chat_start');
                }
                elsif ($content eq 'e') {
                    $self->event('on_chat_end');
                }
                elsif ($content eq 'm') {
                    $self->event('on_chat_mute');
                }
                else {
                    $self->event( on_error => 'Unknown system event: ' . $content );
                }
            }
            elsif ($cmd eq 'S') { # system message ?
                $self->event( on_system_message => $content );
            }
            elsif ($cmd eq 'O') { # other's message
                $self->event( on_message => $content );
            }
            elsif ($cmd eq 'o') { # other's typing
                $self->event( on_typing => $content eq 'd' ? 1 : 0 );
            }
            elsif ($cmd eq 'n') { # my face
                # TODO: support upload faces
            }
            elsif ($cmd eq 'p') { # other's face
                $self->event( on_picture => $content );
            }
            elsif ($cmd eq 'a') { # user count
                $self->event( on_user_count => $content );
            }
        }
    }

    $self->_poll;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

WebService::ChatPad - Module abstract (<= 44 characters) goes here

=head1 SYNOPSIS

  use WebService::ChatPad;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
