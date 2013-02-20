package LWPx::ProxyHandler::Plugin;

use strict;
use warnings;
use parent qw(Class::Accessor::Lite);
use HTTP::Response;

sub create_response {
    my $self = shift;
    return HTTP::Response->new(@_);
}

sub handle {
    my ($self, $request, $ua, $http_config) = @_;
}

sub cb {
    my ($self, $request, $ua, $http_config) = @_;
    return sub {
        $self->handle($request, $ua, $http_config);
    };
}

1;
