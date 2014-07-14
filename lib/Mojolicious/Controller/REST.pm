# ABSTRACT: Mojolicious Controller for RESTful operations
package Mojolicious::Controller::REST;

use Mojo::Base 'Mojolicious::Controller';

sub data {
	my $self = shift;
	my %data = @_;

	my $json = $self->stash('json');

	if ( defined( $json->{data} ) ) {
		@{ $json->{data} }{ keys %data } = values %data;
	}
	else {
		$json->{data} = {%data};
	}

	$self->stash( json => $json );
	return $self;

}

sub message {
	my $self = shift;
	my ( $message, $severity ) = @_;

	$severity //= 'warn';

	my $json = $self->stash('json');

	if ( defined( $json->{messages} ) ) {
		push( $json->{messages}, { text => $message, severity => $severity } );
	}
	else {
		$json->{messages} = [ { text => $message, severity => $severity } ];
	}

	$self->stash( json => $json );
	return $self;
}

sub message_info { $_[0]->message( $_[1], 'info' ) }

sub status {
	my $self   = shift;
	my $status = shift;
	$self->stash( 'status' => $status );
	return $self;
}

1;

__END__

=head1 SYNOPSIS

	# In Mojolicious Controller
	use Mojo::Base 'Mojolicious::Controller::REST';
	
	$self->data( hello => 'world' )->message('Something went wrong');
	
	# renders json response as:
	
	{
		"data":
		{
			"hello": "world"
		},
		"messages":
		[
			{
				"severity": "warn",
				"text": "Something went wrong"
			}
		]
	}
    
=head1 DESCRIPTION

Mojolicious::Controller::REST helps with JSON rendering in RESTful applications. It follows 
and ensures the output of the method in controller adheres to the following output format as JSON:

	{
		"data":
		{
			"<key1>": "<value1>",
			"<key2>": "<value2>",
			...
		},
		"messages":
		[
			{
				"severity": "<warn|info>",
				"text": "<message1>"
			},
			{
				"severity": "<warn|info>",
				"text": "<message2>"
			},
		]
	}



Mojolicious::Controller::REST extends Mojolicious::Controller and adds below methods

=method data

Sets the data element in 'data' array in JSON output. Returns controller object so that
other method calls can be chained.

=method message

Sets an individual message in 'messages' array in JSON output. Returns controller object so that
other method calls can be chained.

A custom severity value can be used by calling message as:

	$self->message('Something went wrong', 'fatal');

	# renders json response as:
	
	{
		"messages":
		[
			{
				"text": "Something went wrong",
				"severity": "fatal"
			}
		]
	}

=method message_info

Similar to message_info, but with severity = 'info'. Returns controller object so that
other method calls can be chained.

=method status

Set the status of response. Returns controller object so that other methods can be chained.

=cut
