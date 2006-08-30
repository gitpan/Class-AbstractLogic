=head1 NAME

Class::AbstractLogic - Handling Logic Abstractions

=cut

package Class::AbstractLogic;
use warnings;
use strict;

use Carp::Clan qw/^Class::AbstractLogic::/;
use aliased 'Class::AbstractLogic::Manager';
use aliased 'Class::AbstractLogic::Base';
use aliased 'Class::AbstractLogic::Action';
use Scalar::Util qw(blessed);

our $VERSION = '0.01_01';

sub NeedSpec   () { 'Class::AbstractLogic::NeedSpec'   }
sub VerifySpec () { 'Class::AbstractLogic::VerifySpec' }

=head1 SYNOPSIS

  # the logic class definition
  package My::Logic::Foo;
  use Class::AbstractLogic-base;

  # a logic action
  action 'add',
   needs [qw(a b)],
  verify { a => sub { /^\d+$/ }, b => sub { /^\d+$/ } },
     sub { $_{a} + $_{b} };

  1;
  ...

  # logic module manager creation
  use Class::AbstractLogic;
  my $calm = Class::AbstractLogic::Manager->new;

  # loading a logic class
  $calm->load_logic(Foo => 'My::Logic::Foo');

  # requesting a result from a logic method
  my $result = $calm->logic('Foo')->add(a => 11, b => 12);

  # $result will be false if an exception was caught
  if ($result) {
    print 'result was ' . $result->value . "\n";
  }
  else {
    print 'exception raised: ' . $result->key . "\n";
    print 'error message: ' . $result->error . "\n";
  }

=head1 DESCRIPTION

This module provides a small framework to abstract logics. It was mostly
thought to have a place for isolated business-logic that does neither fit
in the MVC concepts controllers nor its models.

=head2 Logic Modules

  package FooLogic;
  use warnings;
  use strict;

  use Class::AbstractLogic-base;

  # ... action definitions ...

  1;

You can create a new logic module easily. By C<use>ing C<Class::AbstractLogic>
with the postfix C<-base> you request the installation of action helpers as 
well as the L<Class::AbstractLogic::Base> class into this modules C<@ISA>.

=head2 Action Definitions

  ...
  action 'foo', needs   [qw(field1 field2)], 
                verify  { field1 => sub { ... }, ... },
                sub     { do_stuff_with($_{field1}) };
  ...

The installed helpers are named C<action>, C<needs> and C<verify>. The first
defines the actions name. C<needs> accepts either an arrayref with a list of, 
or a scalar with a single field name that have to be specified in the arguments
to this action. The C<verify> hash reference takes a code reference for each
key representing an argument name. The code ref gets the value passed in C<@_>
and as C<$_>. If it returns a false value, an error is thrown.

C<action> just looks for a code reference in the stream of its arguments to
determine which is the subroutine that actually represents the action. The
arguments passed with the call are available in C<@_> after the first value
representing the current logical module object, and also come in the global
hash C<%_> for easier and more readable access. Via C<&_> you can access
other logical classes:

  action 'foo',
     sub { my $res = _('Bar')->bar(baz => 23); ... }

B<Note> however, that the return values of calls to other logic methods will
return C<Class::AbstractLogic::Result> objects which you have to deal with.
If your action returns a result object, however, it will not be rewrapped in
another result, but just returned itself.

Through the logical module object you have access to the C<config> and C<error>
methods.

=head2 Logic Modules and the Manager, General Usage

  my $calm = Class::AbstractLogic::Manager->new(
    config => { Foo => { foobar => 23 }} );

This creates a new logic module manager. The configuration is logic module
specific. In the above example, a logic module registered under C<Foo> will
have C<{ foobar =E<gt> 23 }> as its config value.

  $calm->load_logic(Foo => 'FooLogicClass');

This loads the class C<FooLogicClass> and registers it in themanager under the
name C<Foo>.

  my $result = $calm->logic('Foo')->foo(field1 => 12, field2 => 13);

This calls the action C<foo> with the arguments C<field1> and C<field2> on the
logic module registered under the name C<Foo>.

=head2 The Result

  if ($result) { print "ok\n" } else { print "not ok\n" }

The boolean value of the result object will be false if an exception was thrown.
If the call succeeded, it will evaluate to true and you can access the value via
the C<result> method or its C<value> alias.

=head2 Logic Exceptions

To provide a facility to handle errors and other exception like things, C<C:AL>
has a built-in exception handling facility. Inside of your actions you can just
throw an exception, which will propagate up to the place the current action was
called from.

  action 'foo',
         sub { my $self = shift;
               $self->throw( foobar => 'Extensive Error Message' ); 
             };

  ...
  my $result = $calm->logic('WithDyingFoo')->foo(bar => 23);

In the above example, the C<$result> will evaluate to false. You can access its
error message through the C<error> method, and its error key (the first argument
you specified, it's for easier flow handling with exceptions) through the C<key>
method. If you need, you can also get to the original exception object through
C<exception>.

=head1 METHODS

=head2 import(@args)

Handles helper installations in your Logic Modules.

=cut

sub import {
    my ($class, @args) = @_;
    my $type = shift @args;

    if (defined($type) and $type =~ /^-?base$/i) {
        $class->import_helpers(scalar caller);
    }
    1;
}

=head2 import_helpers($target)

Internal method that installs the C<action>, C<needs> and C<verify> helpers in
C<$target>.

=cut

sub import_helpers {
    my ($class, $target) = @_;
    no strict 'refs';

    unshift @{$target . '::ISA' }, Base;

    *{$target . '::' . $_} = $class->can('_handle_' . $_)
        for qw/ action
                needs
                verify /;
}

=head2 _handle_action(@args)

Helper Method, creates a new action in a Logic Class.

=cut

sub _handle_action { 
    my ($name, @args) = @_;
    croak 'Logic Action has no name' 
        unless defined($name) and length($name);

    my %tests = (
        code   => sub { ref shift eq 'CODE' },
        needs  => sub { (blessed(shift) || '') eq NeedSpec },
        verify => sub { (blessed(shift) || '') eq VerifySpec },
    );
    my %found = ( name => $name );
    for my $arg (@args) {
        for my $t_key (keys %tests) {
            if ($tests{$t_key}->($arg)) {
                croak "Action Logic '$name' has more than one $t_key argument"
                    if exists $found{$t_key};
                $found{$t_key} = $arg;
            }
        }
    }

    croak "Logic Action '$name' has no code argument"
        unless exists $found{code};

    my $action = Action->new(%found);
    $action->install(scalar(caller), $name);
    1;
}

=head2 _handle_needs($spec)

Helper Method, checks and flags the C<needs> specification.

=cut

sub _handle_needs ($) {
    my $spec = shift;
    $spec = [$spec] if not ref $spec;
    unless (ref $spec eq 'ARRAY') {
        croak 'Logic Action need specification expects ArrayRef or Scalar';
    }
    return bless $spec, NeedSpec;
}

=head2 _handle_verify($spec)

Helper Method, checks and flags the C<verify> specification.

=cut

sub _handle_verify ($) { 
    my $spec = shift;
    croak 'Logic Action verify specification expects HashRef'
        unless ref $spec eq 'HASH';
    return bless $spec, VerifySpec;
}

{
    package Class::AbstractLogic::NeedSpec;
    package Class::AbstractLogic::VerifySpec;
}

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


1;
