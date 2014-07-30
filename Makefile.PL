use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::REST',
  VERSION_FROM => 'lib/Mojolicious/Plugin/REST.pm',
  AUTHOR       => 'Abhishek Shende <abhishekisnot@gmail.com>',
  PREREQ_PM    => {'Mojolicious' => '1.0','Lingua::EN::Inflect'=>'1.895'},
  test         => {TESTS => 't/*.t'}
);
