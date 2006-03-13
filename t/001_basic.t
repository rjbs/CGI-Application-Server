#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib/';

use Test::More tests => 1;

BEGIN {
    use_ok('HTTP::Server::Simple::CGI::Application');
    use_ok('MyCGIApp');
}

{
	package HTTP::Server::Simple::CGI::Application;
	
}

my $server = HTTP::Server::Simple::CGI::Application->new();
$server->cgi_app_class('MyCGIApp');
$server->entry_point('/index.cgi');
$server->server_root('./t/htdocs');
$server->run();

