
package CGI::Application::Server;

use strict;
use warnings;
use Carp;

use Carp         'confess';
use Scalar::Util 'blessed', 'reftype';

our $VERSION = '0.01';

use base qw(HTTP::Server::Simple::CGI HTTP::Server::Simple::Static);

# HTTP::Server::Simple methods

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_); 
	$self->{entry_points} = {};	
	$self->{server_root}  = '.';
	return $self;
}

# accessors

sub server_root {
	my ($self, $server_root) = @_;
	if (defined $server_root) {
		(-d $server_root)
			|| confess "The server root ($server_root) is not found";
		$self->{server_root} = $server_root;
	}
	$self->{server_root};
}

sub entry_points {
	my ($self, $entry_points) = @_;
	if (defined $entry_points) {
		(reftype($entry_points) && reftype($entry_points) eq 'HASH')
			|| confess "The entry points map must be a HASH reference, not $entry_points";
		$self->{entry_points} = $entry_points;
	}
	$self->{entry_points};	
}

# check request

sub is_valid_entry_point {
	my ($self, $uri) = @_;
	foreach my $entry_point (keys %{$self->{entry_points}}) {
		return $self->{entry_points}->{$entry_point}
			if index($uri, $entry_point) == 0;
	}
	return undef;
}

sub handle_request {
	my ($self, $cgi) = @_;
	if (my $entry_point = $self->is_valid_entry_point($ENV{REQUEST_URI})) {
		# NOTE:
		# this does not handle Redirects correctly,.. 
		# how should we handle those?
    	print "HTTP/1.0 200 OK\r\n";
		$entry_point->new->run;		
	}
	else {
    	$self->serve_static($cgi, $self->server_root);
	} 
}

1;

__END__

=pod

=head1 NAME

CGI::Application::Server - A HTTP::Server::Simple subclass for developing CGI::Application

=head1 SYNOPSIS

  use CGI::Application::Server;

  my $server = CGI::Application::Server->new();
  $server->server_root('./htdocs');
  $server->entry_points({
	  '/index.cgi' => 'MyCGIApp',
	  '/admin'     => 'MyCGIApp::Admin'
  });
  $server->run();

=head1 DESCRIPTION

This is a simple L<HTTP::Server::Simple> subclass for use during 
development with L<CGI::Appliaction>. 

=head1 METHODS

=over 4

=item B<new ($port)>

This acts just like C<new> for L<HTTP::Server::Simple>, except it 
will initialize instance slots that we use.

=item B<handle_request>

This will check the request uri and dispatch appropriately, either 
to an entry point, or serve a static file (html, jpeg, gif, etc).

=item B<entry_points (?$entry_points)>

This accepts a HASH reference in C<$entry_points>, which maps 
server entry points (uri) to L<CGI::Application> class names. 
See the L<SYNOPSIS> above for an example.

=item B<is_valid_entry_point ($uri)>

This attempts to match the C<$uri> to an entry point.

=item B<server_root (?$server_root)>

This is the server's document root where all static files will 
be served from.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests, below 
is the L<Devel::Cover> report on this module's test suite.

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
