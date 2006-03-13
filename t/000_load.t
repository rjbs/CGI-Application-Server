#!/usr/bin/perl

use strict;
use warning;

use Test::More tests => 1;

BEGIN {
    use_ok('HTTP::Server::Simple::CGI::Application');
}