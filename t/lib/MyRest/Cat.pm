package MyRest::Cat;
use Mojo::Base 'Mojolicious::Controller::REST';

sub list_cat {
    my $self = shift;
    $self->render( json => { data => [ { id => 1, sound => $self->stash('sound') },
                                       { id => 2, sound => $self->stash('sound') } ] } );
}

sub create_cat {
    my $self = shift;
    $self->data( id => $self->req->json->{id} )->data( sound => $self->stash('sound') );
}

sub read_cat {
    my $self = shift;
    $self->render( json => { data => { id => $self->stash('catId'), sound => $self->stash('sound') } } );
}

sub update_cat {
    my $self = shift;
    $self->render( json => { data => { id => $self->stash('catId'), sound => $self->stash('sound') } } );
}

sub delete_cat {
    my $self = shift;
    $self->render( json => { data => { id => $self->stash('catId'), sound => $self->stash('sound') } } );
}

1;
