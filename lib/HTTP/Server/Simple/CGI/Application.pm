
package HTTP::Server::Simple::CGI::Application;

use strict;
use warnings;
use Carp;

use Carp         'confess';
use Scalar::Util 'blessed';

our $VERSION = '0.01';

use base qw(HTTP::Server::Simple::CGI HTTP::Server::Simple::Static);

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_); 
	$self->{cgi_app_class} = undef;
	$self->{entry_point}   = undef;	
	$self->{server_root}   = '.';
	return $self;
}

sub cgi_app_class {
	my ($self, $cgi_app_class) = @_;
	if (defined $cgi_app_class) {
		($cgi_app_class->isa('CGI::Application'))
			|| confess "You must provide a valid CGI::Application derived class, you gave me: ($cgi_app_class)";
		$self->{cgi_app_class} = $cgi_app_class;
	}
	$self->{cgi_app_class};
}

sub server_root {
	my ($self, $server_root) = @_;
	if (defined $server_root) {
		(-d $server_root)
			|| confess "The server root ($server_root) is not found";
		$self->{server_root} = $server_root;
	}
	$self->{server_root};
}

sub entry_point {
	my ($self, $entry_point) = @_;
	$self->{entry_point} = $entry_point if defined $entry_point;
	$self->{entry_point};	
}

sub is_entry_point {
	my ($self, $uri) = @_;
	my $entry_point = $self->entry_point;
	#warn "URI: $uri";
	#warn "entry_point: $entry_point";	
	return index($uri, $entry_point) == 0;
}

sub handle_request {
	my ($self, $cgi) = @_;
	unless ($self->is_entry_point($ENV{REQUEST_URI})) {
    	$self->serve_static($cgi, $self->server_root);
	} 
	else {	
		# NOTE:
		# this does not handle Redirects correctly,.. 
		# how should we handle those?
    	print "HTTP/1.0 200 OK\r\n";
		$self->cgi_app_class->new->run;			
	}
}

1;

__END__


__END__

=pod

=head1 NAME

HTTP::Server::Simple::CGI::Application - A HTTP::Server::Simple subclass for developing CGI::Application

=head1 SYNOPSIS

  use HTTP::Server::Simple::CGI::Application;

  my $server = HTTP::Server::Simple::CGI::Application->new();
  $server->cgi_app_class('MyCGIApp');
  $server->entry_point('/index.cgi');
  $server->server_root('./t/htdocs');
  $server->run();

=head1 DESCRIPTION

=head1 METHODS

=head2 Overridden HTTP::Server::Simple methods

=over 4

=item B<new>

=item B<handle_request>

=back

=head2 Accessors

=over 4

=item B<cgi_app_class (?$cgi_app_class)>

=item B<entry_point (?$entry_point)>

=item B<server_root (?$server_root)>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests, below is the 
L<Devel::Cover> report on this module's test suite.

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
