use Test::More;
use Test::Mojo;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Plugin::REST';

my $t = Test::Mojo->new('MyRest');

# all test cases tests if the route was intalled correctly...

# get request to collection returns correct stash value...
$t->get_ok('/api/v1/cats')->status_is(200)
    ->json_is( { data => [ { id => 1, sound => 'mew' }, { id => 2, sound => 'mew' } ] } );

# post request to collection responds with stash value...
$t->post_ok( '/api/v1/cats' => json => { id => 3 } )->status_is(200)
    ->json_is( { data => { id => 3, sound => 'mew' } } );

# get request to individual item returns the stash value...
$t->get_ok('/api/v1/cats/1')->status_is(200)->json_is( { data => { id => 1, sound => 'mew' } } );

# put request to individual item returns that stash value...
$t->put_ok( '/api/v1/cats/1' => json => {} )->status_is(200)
    ->json_is( { data => { id => 1, sound => 'mew' } } );

# delete request to individual item returns that stash value...
$t->delete_ok('/api/v1/cats/1')->status_is(200)->json_is( { data => { id => 1, sound => 'mew' } } );

done_testing;
