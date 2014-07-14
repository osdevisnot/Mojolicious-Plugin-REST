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
