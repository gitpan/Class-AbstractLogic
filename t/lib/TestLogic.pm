package TestLogic;
use warnings;
use strict;

use Class::AbstractLogic-base;

action 'simple' => sub { $_{foo} * 23 };

action 'needings',
 needs [qw( foo bar )],
sub {
    return $_{foo} * $_{bar};
};

action 'calling',
 needs [qw( foo )],
sub {
    return _()->calling2(foo => $_{foo}, bar => 10);
};

action 'calling2',
 needs [qw( foo bar )],
sub {
    return $_{foo} * $_{bar};
};

action 'callwide',
 needs [qw(foo)],
sub { _('Foo')->to_call(foo => $_{foo})->result * 2 };

action 'need_w_string',
 needs 'foo',
sub { $_{foo} + 23 };

action 'mult',
 needs [qw( list factor )],
verify { list   => sub { ref shift eq 'ARRAY' },
         factor => sub { $_[0] =~ /^\d+$/ } },
sub { 
    return [map {$_ * $_{factor}} @{$_{list}}];
};

action 'dies',
 needs [qw( foo )],
sub { my ($self) = @_; 
    $self->error(fookey => "The Foo was: $_{foo}") 
};

1;
