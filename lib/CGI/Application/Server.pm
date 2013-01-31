package CGI::Application::Server;

use strict;
use warnings;

use Carp qw( confess );
use CGI qw( param );
use Scalar::Util qw( blessed reftype );
use HTTP::Response;
use HTTP::Status;

our $VERSION = '0.062n1';

use base qw( HTTP::Server::Simple::CGI );
use HTTP::Server::Simple::Static;

# HTTP::Server::Simple methods

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{entry_points} = {};
    $self->{document_root}  = '.';
    $self->{default_index}  = '/index.html';
    return $self;
}

# accessors

sub document_root {
    my ($self, $document_root) = @_;
    if (defined $document_root) {
        (-d $document_root)
            || confess "The server root ($document_root) is not found";
        $self->{document_root} = $document_root;
    }
    $self->{document_root};
}

sub default_index {
    my ($self, $default_index) = @_;
    if (defined $default_index) {
        my $default_url = $self->{document_root};
    $default_url .= $default_index;
        (-f $default_url)
            || confess "The server default_index ($default_url) [$default_index] is not found";
        $self->{default_index} = $default_index;
    }
    $self->{default_index};
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

    # Remove all parameters
    $uri =~ s/\?.*//;

    while ( $uri ) {
        # Check to see if this is an exact match
        if (exists $self->{entry_points}{$uri}) {
            return ($uri, $self->{entry_points}{$uri});
        }

        # Remove the rightmost path element
        $uri =~ s/\/[^\/]*$//;
    }

    # Check to see if there's an entry for '/'
    if (exists $self->{entry_points}{'/'}) {
    return ($uri, $self->{entry_points}{'/'});
    }

    # Didn't find anything. Oh, well.
    return;
}

sub handle_request {
    my ($self, $cgi) = @_;
    if (my ($path, $target) = $self->is_valid_entry_point($ENV{REQUEST_URI})) {
        # warn "$ENV{REQUEST_URI} ($target)\n";
        # warn "\t$_ => " . param( $_ ) . "\n" for param();

        local $ENV{CGI_APP_RETURN_ONLY} = 1;
        (local $ENV{PATH_INFO} = $ENV{PATH_INFO}) =~ s/\A\Q$path//;

        if (-d $target && -x $target) {
            return $self->serve_static($cgi, $target);
        }
        elsif ($target->isa('CGI::Application::Dispatch')) {
          return $self->_serve_response($target->dispatch);
            } elsif ($target->isa('CGI::Application')) {
              if (!defined blessed $target) {
            return $self->_serve_response($target->new->run);
              } else {
            $target->query($cgi);
            return $self->_serve_response($target->run);
              }
        }
        else {
          confess "Target must be a CGI::Application or CGI::Application::Dispatch subclass or the name of a directory that exists and is readable.\n";
        }
    } else {
        my $path = $cgi->path_info();
        if($path=~m/^\/?$/){
           my $file = shift || './t/www/index.html';
           my $index_file = $self->{document_root} . '/'. $self->{default_index};
           if(-f $index_file){ $file = $index_file; }
           if (-f "$file"){
             open (FILE, "<$file");
             while(<FILE>){ print $_; }
             close(FILE);
           }else{
             print "HTTP/1.1 200 OK\n";
             print "Content-type: text/html; charset=iso-8859-1\n\n";
             print qq |<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN"><href><body><a href="/cgi-bin/index.cgi">Welcome</a></body></html>|;
           }
           return 1;
        }
        return $self->serve_static($cgi, $self->document_root);
    }
}

sub _serve_response {
  my ( $self, $stdout ) = @_;

  my $response = $self->_build_response( $stdout );
  print $response->as_string();

  return 1;         # Like ...Simple::Static::serve_static does
}

# Shamelessly stolen from HTTP::Request::AsCGI by chansen
sub _build_response {
    my ( $self, $stdout ) = @_;

    $stdout =~ s{(.*?\x0d?\x0a\x0d?\x0a)}{}xsm;
    my $headers = $1;

    unless ( defined $headers ) {
        $headers = "HTTP/1.1 500 Internal Server Error\x0d\x0a";
    }

    unless ( $headers =~ /^HTTP/ ) {
        $headers = "HTTP/1.1 200 OK\x0d\x0a" . $headers;
    }

    my $response = HTTP::Response->parse($headers);
    $response->date( time() ) unless $response->date;

    my $message = $response->message;
    my $status  = $response->header('Status');

    $response->header( Connection => 'close' );

    if ( $message && $message =~ /^(.+)\x0d$/ ) {
        $response->message($1);
    }

    if ( $status && $status =~ /^(\d\d\d)\s?(.+)?$/ ) {

        my $code    = $1;
        $message = $2 || HTTP::Status::status_message($code);

        $response->code($code);
        $response->message($message);
    }
    my $length = length $stdout;

    if ( $response->code == 500 && !$length ) {

        $response->content( $response->error_as_HTML );
        $response->content_type('text/html');

        return $response;
    }

    $response->add_content($stdout);
    $response->content_length($length);

    return $response;
}


1;

__END__

=pod

=head1 NAME

CGI::Application::Server - A simple HTTP server for developing with CGI::Application

=head1 SYNOPSIS

  use CGI::Application::Server;
  use MyCGIApp;
  use MyCGIApp::Admin;
  use MyCGI::App::Account::Dispatch;
  use MyCGIApp::DefaultApp;

  my $server = CGI::Application::Server->new();
 
  # this CGI::Application object will stay persistent, might not be safe to use
  # in this way - your mileage may vary
  # http://www.mail-archive.com/cgiapp@lists.erlbaum.net/msg08997.html
  my $object = MyOtherCGIApp->new(PARAMS => { foo => 1, bar => 2 });
  
  $server->document_root('./htdocs');
  $server->default_index('/index.html');
  $server->entry_points({
      '/'          => 'MyCGIApp::DefaultApp',
      '/index.cgi' => 'MyCGIApp',
      '/admin'     => 'MyCGIApp::Admin',
      '/account'   => 'MyCGIApp::Account::Dispatch',
      '/users'     => $object,
      '/static'    => '/usr/local/htdocs',
  });
  $server->run();

=head1 DESCRIPTION

This is a simple HTTP server for for use during development with 
L<CGI::Application>. At this moment, it serves our needs in a 
very basic way. The plan is to release early and release often, 
and add features when we need them. That said, we welcome any 
and all patches, tests and feature requests (the ones with which 
are accompanied by failing tests will get priority).

=head1 METHODS

=over 4

=item B<new ($port)>

This acts just like C<new> for L<HTTP::Server::Simple>, except it 
will initialize instance slots that we use.

=item B<handle_request>

This will check the request uri and dispatch appropriately, either 
to an entry point, or serve a static file (html, jpeg, gif, etc).

=item B<entry_points (?$entry_points)>

This accepts a HASH reference in C<$entry_points>, which maps server entry
points (uri) to L<CGI::Application> or L<CGI::Application::Dispatch> class
names or objects or to directories from which static content will be served
by HTTP::Server::Simple::Static.  See the L<SYNOPSIS> above for examples.

=item B<is_valid_entry_point ($uri)>

This attempts to match the C<$uri> to an entry point.

=item B<document_root (?$document_root)>

This is the server's document root where all static files will 
be served from.


=back

=head1 CAVEATS

This is a subclass of L<HTTP::Server::Simple> and all of its caveats 
apply here as well.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests, below 
is the L<Devel::Cover> report on this module's test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt   bran   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 ...CGI/Application/Server.pm   94.4   80.0   53.3  100.0  100.0  100.0   88.3
 Total                          94.4   80.0   53.3  100.0  100.0  100.0   88.3
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 ACKNOWLEDGEMENTS

=over 4

=item The HTTP response handling was shamelessly stolen from L<HTTP::Request::AsCGI> by chansen

=back

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Ricardo SIGNES E<lt>rjbs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
