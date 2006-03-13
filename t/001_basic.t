#!/usr/bin/perl

use strict;
use warning;

use Test::More tests => 1;

BEGIN {
    use_ok('HTTP::Server::Simple::CGI::Application');
}


my $server = HTTP::Server::Simple::CGI::Application->new();
$server->set_cgi_app_instance(MyCGIApp->new());
$server->run();