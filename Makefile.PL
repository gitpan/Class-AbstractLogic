use inc::Module::Install;
use warnings;
use strict;

name                q(Class-AbstractLogic);
abstract_from       q(lib/Class/AbstractLogic.pm);
version_from        q(lib/Class/AbstractLogic.pm);
author              q(Robert 'phaylon' Sedlacek <phaylon@dunkelheit.at>);
license             q(perl);

requires            @$_ for ( ['Exception::Class' => 0],
                              ['Carp::Clan'       => 0],
                              ['Scalar::Util'     => 0],
                              ['aliased'          => 0] );

build_requires      'Test::More' => 0;

WriteAll;

1;
