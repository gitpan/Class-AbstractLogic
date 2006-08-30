package Foo;
use warnings;
use strict;

use Class::AbstractLogic-base;

action 'to_call',
 needs [qw(foo)],
sub { $_{foo} * 2 };

1;
