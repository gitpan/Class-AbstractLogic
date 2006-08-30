=head1 NAME

Class::AbstractLogic::Manager - Manages Abstract Logic Modules

=cut

package Class::AbstractLogic::Manager;
use warnings;
use strict;

use Carp::Clan qr/^Class::AbstractLogic::/;
use aliased 'Class::Inspector';

=head1 DESCRIPTION

This module does the loading, fetching and similar actions of your declared
logic modules.

=head1 METHODS

=head2 new(%args)

Constructor, creates new Management Object and initializes the C<%args>.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless {} => $class;
    $self->_initialize(%args);
    return $self;
}

=head2 load_logic($name, $logic_class)

Loads the specified C<$logic_class> and registers it under the $name in 
itself. The C<config> hashes value for the key C<$name> will be passed
as C<config> for the module.

=cut

sub load_logic {
    my ($self, $name, $logic_class) = @_;

    unless (Inspector->loaded($logic_class)) {
        require(Inspector->filename($logic_class));
    }
    my $logic_object = $logic_class->new(
        config  => $self->_config->{$name} );

    $self->_register_logic_object($name, $logic_object);
    1;
}

=head2 logic($name)

Retrieves a logic module registered under C<$name>. Croaks if none found or
no name supplied.

=cut

sub logic {
    my ($self, $name) = @_;
    croak 'No logic name supplied' 
        unless $name;

    return $self->_fetch_logic($name);
}

=head2 _register_logic_object($name, $object)

Registers the passed C<$object> under the specified C<$name> in this manager.

=cut

sub _register_logic_object {
    my ($self, $name, $object) = @_;
    $self->{logics}{$name} = $object;
    1;
}

=head2 _fetch_logic($name)

Returns logic module if exists, croaks otherwise.

=cut

sub _fetch_logic {
    my ($self, $name) = @_;
    unless ($self->_logic_exists($name)) {
        croak "No logic module with name '$name' registered";
    }
    my $logic = $self->{logics}{$name};
    $logic->set_manager($self);
    return $logic;
}

=head2 _logic_exists($name)

Returns a boolean value depending on the existance of a module registered
as C<$name>.

=cut

sub _logic_exists {
    my ($self, $name) = @_;
    return exists $self->{logics}{$name};
}

=head2 _initialize(%args)

Initializes the arguments.

=cut

sub _initialize {
    my ($self, %args) = @_;
    $self->{config} = $args{config} || {};
    1;
}

=head2 _config()

Config Accessor.

=cut

sub _config {
    my ($self) = @_;
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
