package X::Tiny::Base;

use strict;
use warnings;

my %CALL_STACK;

my %PROPAGATIONS;

=encoding utf-8

=head1 NAME

X::Tiny::Base - super-light exception base class

=head1 SYNOPSIS

    package My::Module::X::Base;

    use parent qw( X::Tiny::Base );

    sub _new {
        my ($class, @args) = @_;

        ...
    }

    sub get {
        my ($self, $attr_name) = @_;

        ...
    }

    sub to_string { ... }

    #If you override this, be sure also to call the base method.
    sub DESTROY {
        my ($self) = @_;

        ...

        #vv This. Be sure to do this in your override method.
        $self->SUPER::DESTROY();
    }

=head1 DESCRIPTION

This base class is meant for you to subclass into your distribution’s own
exception base class (e.g., C<My::Module::X::Base>); you should then
subclass that base class for your distribution’s specific exception classes
(e.g., C<My::Module::X::BadInput>).

C<X::Tiny::Base>, then, serves two functions:

=over

=item 1) It is a useful set of defaults for overridable methods.

=item 2) Framework handling of L<overload> stringification behavior,
e.g., when an uncaught exception is printed.

=back

=head1 SUBCLASS INTERFACE

The default behaviors seem pretty usable and desirable to me, but there may
be circumstances where someone wants other behaviors. Toward that end,
the following methods are meant to be overridden in subclasses:

=head2 I<CLASS>->OVERLOAD()

Returns a boolean to indicate whether this exception class should load
L<overload> as part of creating exceptions. If you don’t want the
memory overhead of L<overload>, then make this return 0. It returns 1
by default.

You might also make this 0 if, for example, you want to handle the
L<overload> behavior yourself. (But at that point, why use this framework?)

=cut

use constant OVERLOAD => 1;

=head2 I<CLASS>->_new( MESSAGE, KEY1 => VALUE1, .. )

The main constructor. Whatever args this accepts are the args that
you should use to create exceptions via your L<X::Tiny> subclass’s
C<create()> method. You’re free to design whatever internal representation
you want for your class: hash reference, array reference, etc.

The default implementation accepts a string message and, optionally, a
list of key/value pairs. It is useful that subclasses of your base class
define their own MESSAGE, so all you’ll pass in is a specific piece of
information about this instance—e.g., an error code, a parameter name, etc.

=cut

sub _new {
    my ( $class, $string, %attrs ) = @_;

    return bless [ $string, \%attrs ], $class;
}

=head2 I<OBJ>->get( ATTRIBUTE_NAME )

Retrieves the value of an attribute.

=cut

sub get {
    my ( $self, $attr ) = @_;

    #Do we need to clone this? Could JSON suffice, or do we need Clone?
    return $self->[1]{$attr};
}

=head2 I<OBJ>->to_string()

Creates a simple string representation of your exception. The default
implementation contains the class and the MESSAGE given on instantiation.

This method’s return value should B<NOT> include a strack trace;
L<X::Tiny::Base>’s internals handle that one for you.

=cut

sub to_string {
    my ($self) = @_;

    return sprintf '%s: %s', ref($self), $self->[0];
}

#----------------------------------------------------------------------

=head1 DESTRUCTOR METHODS

If you define your own C<DESTROY()> method, make sure you also call
C<SUPER::DESTROY()>, or else you’ll get memory leaks as L<X::Tiny::Base>’s
internal tracking of object properties will never be cleared out.

=cut

sub DESTROY {
    my ($self) = @_;

    delete $CALL_STACK{$self->_get_strval()};
    delete $PROPAGATIONS{$self->_get_strval()};

    return;
}

#----------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;

    $class->_check_overload() if $class->OVERLOAD();

    my $self = $class->_new(@args);

    $CALL_STACK{$self->_get_strval()} = [ _get_call_stack(2) ];

    return $self;
}

#----------------------------------------------------------------------

sub PROPAGATE {
    my ($self, $file, $line) = @_;

    push @{ $PROPAGATIONS{$self->_get_strval()} }, [ $file, $line ];

    return $self;
}

my %_OVERLOADED;

sub _check_overload {
    my ( $class, $str ) = @_;

    #cf. eval_bug.readme
    my $eval_err = $@;

    $_OVERLOADED{$class} ||= eval qq{
        package $class;
        use overload (q<""> => __PACKAGE__->can('__spew'));
        1;
    };

    #Should never happen as long as overload.pm is available.
    warn if !$_OVERLOADED{$class};

    $@ = $eval_err;

    return;
}

sub _get_strval {
    my ($self) = @_;

    if ( overload->can('Overloaded') && overload::Overloaded($self) ) {
        return overload::StrVal($self);
    }

    return q<> . $self;
}

sub _get_call_stack {
    my ($level) = @_;

    my @stack;

    while ( my @call = (caller $level)[3, 1, 2] ) {
        my ($pkg) = ($call[0] =~ m<(.+)::>);

        if (!$pkg->isa(__PACKAGE__) && !$pkg->isa('X::Tiny')) {
            push @stack, \@call;
        }

        $level++;
    }

    return @stack;
}

sub __spew {
    my ($self) = @_;

    my $spew = $self->to_string();

    if ( rindex($spew, $/) != (length($spew) - length($/)) ) {
        $spew .= $/ . join( q<>, map { "\tfrom $_->[0]() ($_->[1], line $_->[2])$/" } @{ $CALL_STACK{$self->_get_strval()} } );
    }

    if ( $PROPAGATIONS{ $self->_get_strval() } ) {
        $spew .= join( q<>, map { "\t...propagated at $_->[0], line $_->[1]$/" } @{ $PROPAGATIONS{$self->_get_strval()} } );
    }

    return $spew;
}

#----------------------------------------------------------------------

=head1 REPOSITORY

...

=head1 AUTHOR

Felipe Gasper (FELIPE)

1;
