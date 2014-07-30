# ABSTRACT: Mojolicious Plugin for RESTful operations
package Mojolicious::Plugin::REST;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Exception;
use Lingua::EN::Inflect 1.895 qw/PL/;

our $version = '0.003';

my $http2crud = {
	get    => 'read',
	post   => 'create',
	put    => 'update',
	delete => 'delete',
	list   => 'list',
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

			my $json = $c->stash('json');

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

			my ( $destination, $route_prefix, $separator, $under_lower, $under_plural, $under_id, $resource ) = ( '', '', '_' );
			##
			my $name        = $params->{name};
			my $name_lower  = lc $name;
			my $name_plural = PL( $name_lower, 10 );
			my $route_id    = ":" . $name_lower . "Id";
			#
			my $under = $params->{under};
			if ( defined($under) ) {
				$under_lower  = lc $under;
				$under_plural = PL( $under_lower, 10 );
				$under_id     = ":" . $under_lower . "Id";
				$separator    = "_" . $under_lower . "_";
			}

			#
			my $readonly = $params->{readonly} // 0;
			#
			foreach my $modifier (qw(prefix version)) {
				if ( defined $options->{$modifier} && $options->{prefix} ne '' ) {
					$route_prefix .= "/" . $options->{$modifier};
				}
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
			$destination = $options->{http2crud}->{list} . $separator . $name_plural;
			$resource->get->to( '#' . $destination )->name($destination);

			# POST to resource collection
			if ( !$readonly ) {
				$destination = $options->{http2crud}->{post} . $separator . $name_lower;
				$resource->post->to( '#' . $destination )->name($destination);
			}

			# Install routes for single resource #
			my $ids = [];
			if ( defined( $params->{types} ) ) {
				$ids = $params->{types};
			}
			else {
				push @$ids, ":" . $name_lower . "Id";
			}

			foreach my $route_id (@$ids) {
				if ( defined( $params->{types} ) ) {
					$controller = $params->{controller} // $name . '::' . ucfirst($route_id) . "#";
				}
				if ( defined($under) ) {
					$resource = $routes->route( "$route_prefix/$under_plural/$under_id/$name_plural/$route_id", "$route_id" => qr/\d+/ )
						->to( $controller, idname => "$route_id" )->name("$under_lower$name_lower");
				}
				else {
					$resource = $routes->route( "$route_prefix/$name_plural/$route_id", "$route_id" => qr/\d+/ )->to( $controller, idname => "$route_id" )->name("$name_lower");
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
		}
	);
}

1;

__END__

=head1 SYNOPSIS
	
	# In Mojolicious application
	$self->plugin( 'REST', { prefix => 'api', version => 'v1', } );
	
	$self->routes->rest_routes( name => 'Account' );
	
	# Installs following routes:
    # +-------------+-----------------------------+-------------------------+
	# | HTTP Method |             URL             |          Route          |
	# +-------------+-----------------------------+-------------------------+
	# | GET         | /api/v1/accounts            | Account::list_accounts  |
	# | POST        | /api/v1/accounts            | Account::create_account |
	# | GET         | /api/v1/accounts/:accountId | Account::read_account   |
	# | PUT         | /api/v1/accounts/:accountId | Account::update_account |
	# | DELETE      | /api/v1/accounts/:accountId | Account::delete_account |
	# +-------------+-----------------------------+-------------------------+
	
	$routes->rest_routes( name => 'Feature', under => 'Account' );
	
	# Installs following routes:
	# +-------------+-------------------------------------------------+---------------------------------+
	# | HTTP Method |                       URL                       |              Route              |
	# +-------------+-------------------------------------------------+---------------------------------+
	# | GET         | /api/v1/accounts/:accountId/features            | Feature::list_account_features  |
	# | POST        | /api/v1/accounts/:accountId/features            | Feature::create_account_feature |
	# | GET         | /api/v1/accounts/:accountId/features/:featureId | Feature::read_account_feature   |
	# | PUT         | /api/v1/accounts/:accountId/features/:featureId | Feature::update_account_feature |
	# | DELETE      | /api/v1/accounts/:accountId/features/:featureId | Feature::delete_account_feature |
	# +-------------+-------------------------------------------------+---------------------------------+
	
	$routes->rest_routes( name => 'Product', under => 'Account', types => [qw(FTP SSH)] );
	
	# Installs following routes:	
	# +-------------+------------------------------------------+--------------------------------------+
	# | HTTP Method |                   URL                    |                Route                 |
	# +-------------+------------------------------------------+--------------------------------------+
	# | GET         | /api/v1/accounts/:accountId/products     | Product::list_account_products       |
	# | POST        | /api/v1/accounts/:accountId/products     | Product::create_account_product      |
	# | GET         | /api/v1/accounts/:accountId/products/FTP | Product::FTP::read_account_product   |
	# | PUT         | /api/v1/accounts/:accountId/products/FTP | Product::FTP::update_account_product |
	# | DELETE      | /api/v1/accounts/:accountId/products/FTP | Product::FTP::delete_account_product |
	# | GET         | /api/v1/accounts/:accountId/products/SSH | Product::SSH::read_account_product   |
	# | PUT         | /api/v1/accounts/:accountId/products/SSH | Product::SSH::update_account_product |
	# | DELETE      | /api/v1/accounts/:accountId/products/SSH | Product::SSH::delete_account_product |
	# +-------------+------------------------------------------+--------------------------------------+
	
	
=head1 DESCRIPTION

L<Mojolicious::Plugin::REST> adds various helpers for L<REST|http://en.wikipedia.org/wiki/Representational_state_transfer>ful
L<CRUD|http://en.wikipedia.org/wiki/Create,_read,_update_and_delete> operations via
L<HTTP|http://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol> to the app.

As much as possible, it tries to follow L<RESTful API Design|https://blog.apigee.com/detail/restful_api_design> principles from Apigee.

Used in conjuction with L<Mojolicious::Controller::REST>, this module makes building RESTful application a breeze. 

This module is inspired from L<Mojolicious::Plugin::RESTRoutes>.

=head1 MOJOLICIOUS HELPERS

=head2 rest_routes

A routes shourtcut to easily add RESTful routes for a resource.

=head1 MOJOLICIOUS HOOKS

This module installs an before_render application hook, which gurantees JSON output. Refer L<Mojolicious::Controller::REST> documentation for output format.

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

This option can be used for associations.

=item types

This option can be used to specify types of resources available in application.

=back

=head1 PLUGIN OPTIONS

=over

=item prefix

If present, this option will be added before every route created. 

=item version

If present, api version given will be added before every route created (but after prefix).

=item http2crud

If present, given HTTP to CRUD mapping will be used to determine method names. Default mapping:

	get     ->  read
	post    ->  create
	put     ->  update
	delete  ->  delete
	list    ->  list

=back

=cut
