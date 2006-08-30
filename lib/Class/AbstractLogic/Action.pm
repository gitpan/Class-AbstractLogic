=head1 NAME

Class::AbstractLogic::Action - Encapsulates a Logic Action

=cut

package Class::AbstractLogic::Action;
use warnings;
use strict;

use Carp::Clan qw/^Class::AbstractLogic::/;
use aliased 'Class::AbstractLogic::Result';
use Scalar::Util qw(weaken);

=head1 DESCRIPTION

Holds anything to do with a logical action method. These are installed
in the requesting package at runtime and contain verification and other
action call related logic. You should not create an object of this class
by yourself, but use L<Class::AbstractLogic>s C<action> helper.

=head1 METHODS

=head2 new(%args)

Creates new Action and C<_initialize>s the C<%args>.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless {} => $class;
    $self->_initialize(%args);
    return $self;
}

=head2 install($target_class, $target_name)

Installs this action in the C<$target_class> under the C<$target_name>.

=cut

sub install {
    my ($self, $class, $name) = @_;

    {   no strict 'refs';
        *{$class . '::' . $name} = sub {
            my ($logic_module, %args) = @_;
            return $self->execute($logic_module, %args);
        };
    }
    1;
}

=head2 execute($logic_module, %args)

Executes this action after verifying the C<%args>. This also provides the
C<%_> and C<&_> globals.

=cut

sub execute {
    my ($self, $lm, %args) = @_;
    $self->_verify_arguments(%args);
    no warnings 'redefine';
    local *_ = sub { 
        my $name = shift;
        return $lm unless $name;
        return $lm->_manager->logic($name) ;
    };
    local %_ = %args;
    return Result->capture($self->_code, $lm, %args);
}

=head2 _verify_arguments(%args)

Verifies if all needed values are in C<%args> and if all passed values pass
their verification constraints.

=cut

sub _verify_arguments {
    my ($self, %args) = @_;

    my %needed = map {($_, 0)} @{$self->_needs||[]};
    $needed{$_}++ for keys %args;

    if (my @missing = grep {!$needed{$_}} keys %needed) {
        croak sprintf 'Missing %s argument(s) for %s Logic Action',
            join(', ' => @missing), $self->_name;
    }

    for my $f_name (keys %args) {
        next unless exists $self->_verify->{$f_name};
        my $test = $self->_verify->{$f_name};
        unless ($test->($args{$f_name})) {
            croak "Argument '$f_name' did not pass verification";
        }
    }
    1;
}

=head2 _code() / _needs() / _name() / _verify()

Accessors for the actions properties.

=head2 _manager()

Contains the current executions L<Class::AbstractLogic::Manager>.

=cut

sub _code    { shift->{code}    }
sub _needs   { shift->{needs}   }
sub _name    { shift->{name}    }
sub _verify  { shift->{verify}  }
sub _manager { shift->{manager} }

=head2 _initialize(%args)

Initializes the C<%args>.

=cut

sub _initialize {
    my ($self, %args) = @_;
    $self->{$_} = $args{$_} for keys %args;
    weaken($self->{manager});
    $self->{verify} ||= {};
    1;
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
