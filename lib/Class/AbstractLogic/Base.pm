=head1 NAME

Class::AbstractLogic::Base

=cut

package Class::AbstractLogic::Base;
use warnings;
use strict;

use Scalar::Util qw(weaken);
use aliased 'Class::AbstractLogic::Result';

=head1 DESCRIPTION

This is the base class for all logic modules.

=head1 METHODS

=head2 new(%args)

Constructor, builds object and C<_initialize>s C<%args>.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless {} => $class;
    $self->_initialize(%args);
    return $self;
}

=head2 _initialize(%args)

General argument initializations.

=cut

sub _initialize {
    my ($self, %args) = @_;
    $self->{config} = $args{config} || {};
    1;
}

=head2 set_manager($manager)

Sets the modules current executive manager.

=cut

sub set_manager {
    my ($self, $manager) = @_;
    $self->{manager} = $manager;
    weaken($self->{manager});
    1;
}

=head2 error($key, $message) / throw($key, $message)

Throws a logical Exception, which can be accessed via the 
L<Class::AbstractLogic::Result> object returned from your call.

=cut

sub error {
    my ($self, $key, $error) = @_;
    Result->throw_exception($key, $error);
}

*throw = \&error;

=head2 _manager()

Returns the current executive manager.

=cut

sub _manager { shift->{manager} }

=head2 config($name)

Accesses this logic modules configuration. If a name is supplied, the
hash value corresponding to that key is returned, if omitted, the whole
is returned.

=cut

sub config {
    my ($self, $name) = @_;
    return $self->{config}{$name} if defined $name;
    return $self->{config};
}

=head1 SEE ALSO

L<Class::AbstractLogic>

=head1 AUTHOR

Robert 'phaylon' Sedlacek C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
