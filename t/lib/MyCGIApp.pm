package MyCGIApp;

use base 'CGI::Application';

sub setup {
	my $self = shift;
	$self->start_mode('mode1');
	$self->mode_param('rm');
	$self->run_modes(
	        'mode1' => 'hello_world',
	        'mode2' => 'goodbye_world',		
	);
}	

sub hello_world {
	return "<HTML><BODY><H1>Hello World!</H1><HR>" . 
		   "<A HREF='index.cgi?rm=mode2'>Goodbye</A>" . 
		   "</BODY></HTML>";
}

sub goodbye_world {
	return "<HTML><BODY><H1>Goodbye World!</H1><HR>" . 
	       "<A HREF='index.cgi?rm=mode1'>Hello</A>" . 
	   	   "</BODY></HTML>";		
}

1;