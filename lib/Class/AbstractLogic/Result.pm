=head1 NAME

Class::AbstractLogic::Result - Result for a Logic Object Call

=cut

package Class::AbstractLogic::Result;
use warnings;
use strict;

use Exception::Class
    ( 'Class::AbstractLogic::Result::Exception' 
        => { fields => [qw(key)] } );

use overload
    q(bool)  => \&is_ok,
    q(${})   => \&result,
    fallback => 1;

use Scalar::Util qw(blessed);

sub Exception   () { 'Class::AbstractLogic::Result::Exception' }
sub default_key () { 'misc' }

=head1 DESCRIPTION

An object of this class is returned when a method on a logic object got 
called. You should not create this object directly.

=head1 METHODS

=head2 new(%args)

Constructor, 

=cut

sub new {
    my ($class, %args) = @_;
    return bless \%args => $class;
}

=head2 capture($code, @arguments)

Calls the C<$code> reference with the C<@arguments> and builds a Result
object. If this is used as an object- instead of a class-method, it just
resets the objects value appropriately.

=cut

sub capture {
    my ($self, $code, @args) = @_;
    
    $self = $self->new unless ref($self);
    my $result = eval { $code->( @args ) };
    return $result if blessed($result) and $result->isa(__PACKAGE__);
    
    if (my $e = Exception::Class->caught(Exception)) {
        $self->{is_failed}  = 1;
        $self->{key}        = $e->key || default_key;
        $self->{error}      = $e->message;
        $self->{exception}  = $e;
        $self->{result}     = undef;
    }
    elsif ($@) { die $@ }
    else {
        $self->{$_}         = undef for qw(is_failed key error exception);
        $self->{result}     = $result;
    }

    return $self;
}

=head2 throw_exception($key, $error)

Throws an exception. Since this class knows how to handle exceptions, it also
is the one that knows how to throw them. No matter if class or object method,
this simply throws an Exception with the given values.

=cut

sub throw_exception {
    my (undef, $key, $error) = @_;
    Exception->throw(error => $error, key => $key);
}

=head2 is_ok() / is_failed()

Return the boolean value telling if this result caught an exception, or succeeded.

=cut

sub is_ok       { !   shift->{is_failed} }
sub is_failed   { ! ! shift->{is_failed} }

=head2 result() / value()

Returns the captured result value. Will be C<undef> if an exception was thrown.

=cut

sub result      { shift->{result} }

=head2 key() / error() / exception()

These hold the corresponding values or C<undef> if the request succeeded. The
C<exception> is the original exception object, C<error> the message and C<key>
the specified error key.

=cut

sub key         { shift->{key} }
sub error       { shift->{error} }
sub exception   { shift->{exception} }

*value = \&result;

=head1 SEE ALSO

L<Class::AbstractLogic>

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This program is free software, you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut

1;
