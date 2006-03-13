
package HTTP::Server::Simple::CGI::Application;

use strict;
use warnings;

use IO::Capture::Stdout;

our $VERSION = '0.01';

use base qw(HTTP::Server::Simple::CGI HTTP::Server::Simple::Static);

my $CGI_APPLICATION;

sub set_cgi_app_instance {
	my ($class, $cgi_app) = @_;
	(blessed($cgi_app) && $cgi_app->isa('CGI::Application'))
		|| confess "You must provide a valid CGI::Application instance, not (" . ($cgi_app || 'undef') . ")"
	$CGI_APPLICATION = $cgi_app;
}

sub handle_request {
	my($self, $cgi) = @_;

	my $url = "http://localhost" . $ENV{REQUEST_URI};

	if ($url =~ /\.(gif|png|jpeg|css|js)/) {
		$self->serve_static($cgi, ".");
	} else {
	    my $capture = IO::Capture::Stdout->new();
	    $capture->start();		
		$CGI_APPLICATION->run();
	    $capture->stop();
	    my $output = join '', $capture->read;		

		if ($output =~ /302/) {
			$output = "HTTP/1.0 302 OK\n$output";
		} else {
			$output = "HTTP/1.0 200 OK\n$output";
		}

		print $output;
	}
}

1;

__END__


__END__

=pod

=head1 NAME

HTTP::Server::Simple::CGI::Application - A HTTP::Server::Simple subclass for developing CGI::Application

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<handle_request>

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