package LWPx::ProxyHandler;

use strict;
use warnings;
use 5.008005;

use Carp;
use List::MoreUtils qw(any part);
use Module::Load;
use Module::Loaded;

our $VERSION = '0.0.1';

sub new {
    my ($proto, $ua) = @_;
    unless (UNIVERSAL::isa($ua, "LWP::UserAgent")) {
        croak("\$ua argument is not a LWP::UserAgent or its subclass");
    }
    bless { 
        ua    => $ua,
        specs => [],
    } => $proto;
}

sub connect {
    my ($self, $match, $plugin, $plugin_args) = @_;
    my $matchspec = _to_match_spec($match);

    $plugin = (index($plugin, "+") == 0) ?
        substr($plugin, 1) : "LWPx::ProxyHandler::Plugin::" . $plugin;

    unless (is_loaded $plugin) {
        load $plugin;
    }

    my $plugin_obj = $plugin->new($plugin_args);
    $self->{ua}->add_handler(
        request_send => $plugin_obj->cb, %$matchspec
    );
    push(@{$self->{specs}}, $matchspec);
    $self;
}

sub disconnect_all {
    my $self = shift;
    my $ua = $self->{ua};
    for my $matchspec (@{$self->{specs}}) {
        $ua->remove_handler("request_send", %$matchspec);
    }
}

sub DESTROY {
    shift->disconnect_all;
}

sub _to_match_spec {
    my ($match) = @_;
    %$match = (
        protocols => [qw/http https/],
        methods   => [qw/GET/],
        origins   => undef,
        path      => "/",
        %$match
    );

    my %matchspec;

    if (my $protocols = _is_valid_match_field($match->{protocols})) {
        $matchspec{m_scheme} = $protocols;
    }

    if (my $methods = _is_valid_match_field($match->{methods})) {
        $matchspec{m_method} = $match->{methods};
    }

    if (my $origins = _is_valid_match_field($match->{origins})) {
        my ($hosts, $host_port_list) = 
            map { _is_valid_match_field($_) }
            part { m/\:\d+$/ } @$origins;

        if ($host_port_list) {
            $matchspec{m_host_port} = $host_port_list;
        }

        if ($hosts) {
            $matchspec{m_host} = $hosts;
        }
    }

    if (my $path = _is_valid_match_field($match->{path}) ) {
        $matchspec{m_path_prefix} = $path;
    }

    return \%matchspec;
}

sub _is_valid_match_field {
    my $field = shift;

    return unless defined $field;

    if (ref $field eq "ARRAY") {
        my @fields = grep { defined($_) && length($_) } @$field;
        return @fields > 0 ? [ @fields ] : undef;
    }

    if (!ref $field && length $field > 0) {
        return [ $field ];
    }
}

1;
__END__

=encoding utf8

=head1 NAME

LWPx::ProxyHandler - ...

=head1 SYNOPSIS

  use LWPx::ProxyHandler;

=head1 DESCRIPTION

LWPx::ProxyHandler is

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 METHODS

=over 4

=item C<< new(LWP::UserAgent $ua) >>

=item C<< connect(\%match, $plugin, \%plugin_args) >>

  $proxy_handler->map(
      { 
        protocols => [qw/http https/],
        methods   => [qw/GET/], 
        path      => "/"
      },
      File => { 
        root => '/path/to/dir'
      }
  );

=item C<< disconnect_all() >>

=item C<< DESTROY() >>

=back

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Toru Yamaguchi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

