#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib/';

use Test::More tests => 23;

use Test::Exception;
use Test::HTTP::Server::Simple;
use Test::WWW::Mechanize;

BEGIN {
    use_ok('HTTP::Server::Simple::CGI::Application');
    use_ok('MyCGIApp');
}

{
	package TestServer;
	use base qw/
		Test::HTTP::Server::Simple
		HTTP::Server::Simple::CGI::Application
	/;
}

my $server = TestServer->new();
isa_ok($server, 'HTTP::Server::Simple::CGI::Application');
isa_ok($server, 'HTTP::Server::Simple');

is_deeply($server->entry_points, {}, '... no entry-point yet');
$server->entry_points({
	'/index.cgi' => 'MyCGIApp'
});
is_deeply($server->entry_points, { '/index.cgi' => 'MyCGIApp' }, '... we have an entry point now');

is($server->server_root, '.', '... got the default server root');
$server->server_root('./t/htdocs');
is($server->server_root, './t/htdocs', '... got the new server root');

my $url_root = $server->started_ok("start up my web server");

my $mech = Test::WWW::Mechanize->new();

# test our static index page

$mech->get_ok($url_root.'/index.html', '... got the index.html page okay');
$mech->title_is('Test Static Index Page', '... got the right page title for index.html');

# test out entry point page

$mech->get_ok($url_root.'/index.cgi', '... got the index.cgi page start-point okay');
$mech->title_is('Hello', '... got the right page title for index.cgi');

# test with query params

$mech->get_ok($url_root.'/index.cgi?rm=mode1', '... got the index.cgi page okay');
$mech->title_is('Hello', '... got the right page title for index.cgi (hello)');

$mech->get_ok($url_root.'/index.cgi?rm=mode2', '... got the index.cgi page okay');
$mech->title_is('Goodbye', '... got the right page title for index.cgi (goodbye)');

# test with extra path info after the entry point

$mech->get_ok($url_root.'/index.cgi/test', '... got the index.cgi page okay (even with extra path info)');
$mech->title_is('Hello', '... got the right page title for index.cgi (even with extra path info)');

$mech->get_ok($url_root.'/index.cgi/test?rm=mode1', '... got the index.cgi page okay (even with extra path info)');
$mech->title_is('Hello', '... got the right page title for index.cgi (even with extra path info)');

$mech->get_ok($url_root.'/index.cgi/test?rm=mode2', '... got the index.cgi page okay (even with extra path info)');
$mech->title_is('Goodbye', '... got the right page title for index.cgi (even with extra path info)');
