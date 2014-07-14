# ABSTRACT: Mojolicious Plugin for RESTful operations
package Mojolicious::Plugin::REST;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Exception;
use Lingua::EN::Inflect 1.895 qw/PL/;
use Mojo::Util qw(dumper);

my $http2crud = {
	get     => 'read',
	post    => 'create',
	put     => 'update',
	delete  => 'delete',
	get_col => 'read_all',
};

sub register {
	my $self    = shift;
	my $app     = shift;
	my $options = { @_ ? ( ref $_[0] ? %{ $_[0] } : @_ ) : () };

	foreach my $method ( keys %$http2crud ) {
		$options->{http2crud}->{$method} = $http2crud->{$method} unless exists $options->{http2crud}->{$method};
	}

	$app->hook(
		before_render => sub {
			my $c = shift;
			return unless $c->app->mode ne 'development';
			my $json = $c->stash('json');
			$app->log->debug( "Got json " . dumper($json) );
			unless ( defined $json->{data} ) {
				$json->{data} = {};
				$c->stash( 'json' => $json );
			}
			unless ( defined $json->{messages} ) {
				$json->{messages} = [];
				$c->stash( 'json' => $json );
			}
		}
	);

	$app->routes->add_shortcut(
		rest_routes => sub {
			my $routes = shift;
			my $params = { @_ ? ( ref $_[0] ? %{ $_[0] } : @_ ) : () };

			Mojo::Exception->throw('Route name is required in rest_routes') unless defined $params->{name};

			my ( $destination, $route_prefix, $separator ) = ( '', '', '_' );
			##
			my $name        = $params->{name};
			my $name_lower  = lc $name;
			my $name_plural = PL( $name_lower, 10 );
			my $route_id    = ":" . $name_lower . "id";
			#
			my $under = $params->{under};
			my ( $under_lower, $under_plural, $under_id, $resource );
			if ( defined($under) ) {
				$under_lower  = lc $under;
				$under_plural = PL( $under_lower, 10 );
				$under_id     = ":" . $under_lower . "id";
				$separator    = "_" . $under_lower . "_";
			}

			#
			my $readonly = $params->{readonly} // 0;
			#
			if ( defined $options->{prefix} && $options->{prefix} ne '' ) {
				$route_prefix .= "/" . $options->{prefix};
			}
			#
			if ( defined $options->{version} && $options->{version} ne '' ) {
				$route_prefix .= "/" . $options->{version};
			}
			##
			my $controller = $params->{controller} // "$name#";

			# Install routes for resource collection #
			if ( defined($under) ) {
				$resource = $routes->route("$route_prefix/$under_plural/$under_id/$name_plural")->to($controller)->name("$under_lower$name_plural");
			}
			else {
				$resource = $routes->route("$route_prefix/$name_plural")->to($controller)->name($name_plural);
			}

			# GET resource collection
			$destination = $options->{http2crud}->{get_col} . $separator . $name_plural;
			$resource->get->to( '#' . $destination )->name($destination);

			# POST to resource collection
			if ( !$readonly ) {
				$destination = $options->{http2crud}->{post} . $separator . $name_lower;
				$resource->post->to( '#' . $destination )->name($destination);
			}
			#

			##### Install routes for single resource #####

			if ( defined($under) ) {
				$resource = $routes->route( "$route_prefix/$under_plural/$under_id/$name_plural/$route_id", "$route_id" => qr/\d+/ )
					->to( $controller, idname => "$route_id" )->name("$under_lower$name_lower");
			}
			else {
				$resource = $routes->route( "$route_prefix/$name_plural/$route_id", "$route_id" => qr/\d+/ )
					->to( $controller, idname => "$route_id" )->name("$name_lower");
			}

			# GET a single resource
			$destination = $options->{http2crud}->{get} . $separator . $name_lower;
			$resource->get->to( '#' . $destination )->name($destination);

			if ( !$readonly ) {

				# PUT requests - updates a resource
				$destination = $options->{http2crud}->{put} . $separator . $name_lower;
				$resource->put->to( '#' . $destination )->name($destination);

				# DELETE requests - updates a resource
				$destination = $options->{http2crud}->{delete} . $separator . $name_lower;
				$resource->delete->to( '#' . $destination )->name($destination);
			}
		}
	);
}

1;
__END__
=head1 SYNOPSIS
	
	# In Mojolicious application
	$self->plugin( 'REST', { prefix => 'api', version => 'v1', } );
	$self->routes->rest_routes( name => 'User' );
	
	# Installs following routes:
    # +-------------+-----------------------+------------------------+
    # | HTTP Method |          URL          |         Route          |
    # +-------------+-----------------------+------------------------+
    # | GET         | /api/v1/users         | User::read_all_users() |
    # | POST        | /api/v1/users         | User::create_user()    |
    # | GET         | /api/v1/users/:userid | User::read_user()      |
    # | PUT         | /api/v1/users/:userid | User:update_user()     |
    # | DELETE      | /api/v1/users/:userid | User:delete_user()     |
    # +-------------+-----------------------+------------------------+ 
	
=head1 DESCRIPTION

Mojolicious::Plugin::REST adds various helpers for L<REST|http://en.wikipedia.org/wiki/Representational_state_transfer>ful
L<CRUD|http://en.wikipedia.org/wiki/Create,_read,_update_and_delete> operations via HTTP to the app.

As much as possible, it tries to follow L<RESTful API Design|https://blog.apigee.com/detail/restful_api_design> principles from Apigee.

This module is inspired from L<Mojolicious::Plugin::RESTRoutes>.

=head1 MOJOLICIOUS HELPERS

=head2 rest_routes

rest_routes shourtcut can be used to easily add RESTful routes for a resource. For example,

	$routes->rest_routes( name => 'User' );
	
	# Installs following routes (if $r->namespaces == ['My::App']) :-
	#+-------------+----------------+---------------------------------+
	#| HTTP Method |      URL       |              Route              |
	#+-------------+----------------+---------------------------------+
	#| GET         | /users         | My::App::User::read_all_users() |
	#| POST        | /users         | My::App::User::create_user()    |
	#| GET         | /users/:userid | My::App::User::read_user()      |
	#| PUT         | /users/:userid | My::App::User:update_user()     |
	#| DELETE      | /users/:userid | My::App::User:delete_user()     |
	#+-------------+----------------+---------------------------------+

The target controller has to implement the following methods:
 
=over 4
 
=item *
 
read_all_users
 
=item *
 
create_user
 
=item *
 
read_user
 
=item *
 
update_user
 
=item *
 
delete_user
 
=back

=head1 MOJOLICIOUS HOOKS

This module installs an before_render application hook, which gurantees JSON output in non dev mode.

=head1 OPTIONS

Following options can be used to control route creation:

=over

=item name

The name of the resource, e.g. 'User'. This name will be used to build the route URL as well as the controller name.

=item readonly

If true, no create, update or delete routes will be created.


=item controller

By default, resource name will be converted to CamelCase controller name. You can change it by providing controller name.

If customized, this option needs a full namespace of the controller class.

=item under

This option can be used for associations. For Example:
    
    # Mojolicious
    $self->routes->rest_routes( name => 'Feature', under => 'User' );
    
    # Installs following routes (if $r->namespaces == ['My::App']) :-
	# +-------------+-------------------------------------------+-----------------------------------------+
	# | HTTP Method |                    URL                    |                  Route                  |
	# +-------------+-------------------------------------------+-----------------------------------------+
	# | GET         | /api/v1/users/:userid/features            | My::App::User::read_all_user_features() |
	# | POST        | /api/v1/users/:userid/features            | My::App::User::create_user_feature()    |
	# | GET         | /api/v1/users/:userid/features/:featureid | My::App::User::read_user_feature()      |
	# | PUT         | /api/v1/users/:userid/features/:featureid | My::App::User::update_user_feature()    |
	# | DELETE      | /api/v1/users/:userid/features/:featureid | My::App::User::delete_user_feature()    |
	# +-------------+-------------------------------------------+-----------------------------------------+

=back

=head1 PLUGIN OPTIONS

=over

=item prefix

If present, this option will be added before every route created. e.g.

    # Mojolicious
    $app->plugin(REST => { prefix => 'api' });

    # Installs following routes:
	# +-------------+--------------------+---------------------------------+
	# | HTTP Method |        URL         |              Route              |
	# +-------------+--------------------+---------------------------------+
	# | GET         | /api/users         | My::App::User::read_all_users() |
	# | POST        | /api/users         | My::App::User::create_user()    |
	# | GET         | /api/users/:userid | My::App::User::read_user()      |
    # ...

=item version

If present, api version given will be added before every route created (but after prefix). e.g.

	# Mojolicious
    $app->plugin(REST => { version => 'v1' });

    # Installs following routes:
	# +-------------+-------------------+---------------------------------+
	# | HTTP Method |        URL        |              Route              |
	# +-------------+-------------------+---------------------------------+
	# | GET         | /v1/users         | My::App::User::read_all_users() |
	# | POST        | /v1/users         | My::App::User::create_user()    |
	# | GET         | /v1/users/:userid | My::App::User::read_user()      |
    # ...

And if both prefix and version are present

    # Mojolicious
    $app->plugin(REST => { prefix => 'api', version => 'v1' });

    # Installs following routes:
	# +-------------+-----------------------+---------------------------------+
	# | HTTP Method |          URL          |              Route              |
	# +-------------+-----------------------+---------------------------------+
	# | GET         | /api/v1/users         | My::App::User::read_all_users() |
	# | POST        | /api/v1/users         | My::App::User::create_user()    |
	# | GET         | /api/v1/users/:userid | My::App::User::read_user()      |
    # ...

=item http2crud

If present, given HTTP to CRUD mapping will be used to determine method names. Default mapping:

	get     ->  read
	post    ->  create
	put     ->  update
	delete  ->  delete
	get_col ->  read_all  # deaviates over best practices, 
	                      # but makes it simple to distinguish method names for
	                      # single resource vs for collection

=back

=cut
