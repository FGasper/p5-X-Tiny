package X::Tiny;

=encoding utf-8

=head1 NAME

X::Tiny - Base class for a bare-bones exception factory

=head1 SYNOPSIS

    package My::Module::X;

    use parent qw( X::Tiny );

    #----------------------------------------------------------------------

    package My::Module::X::IO;

    use parent qw( X::Tiny::Base );

    #----------------------------------------------------------------------

    package My::Module::X::Blah;

    use parent qw( X::Tiny::Base );

    sub _new {
        my ($class, @args) = @_;

        my $self = $class->SUPER::_new('Blah blah, @args);

        return bless $self, $class;
    }

    #----------------------------------------------------------------------

    package main;

    local $@;   #always!
    eval {
        die My::Module::X->create('IO', 'The message', { key1 => val1, … });
    };

    if ( my $err = $@ ) {
        print $err->get('key1');
    }

=head1 DESCRIPTION

This stripped-down, purposely limited exception framework provides a baseline
of functionality for distributions that want to expose exception
hierarchies.

=head1 BENEFITS OF EXCEPTIONS

L<Try::Tiny>’s documentation provides some nice insight as to why exceptions
are better for Perl than the C-style “return in failure” pattern.

=head1 FEATURES

=over

=item * Super-lightweight: No exceptions are loaded until they’re needed.

=item * Simple, flexible API

=item * String overload with stack trace

=item * Minimal code necessary

=back

=head1 USAGE

You’ll first create a factory class that subclasses C<X::Tiny>. All of your
exceptions must exist under that factory class’s namespace. (See the SYNOPSIS
for an example.)

Each exception class must subclass C<X::Tiny::Base>. Exception objects
are instantiated by the C<create()> class method of your factory class.
See C<X::Tiny::Base> for more information about the features that that
module exposes to subclasses.

=head1 OVERLOADING

C<X::Tiny::Base> will treat each exception class with L<overload> such that
a stringified/concatenated exception will include a stack trace. This will
include information about any PROPAGATE invocations (cf. C<perldoc -f die>).

=cut

use strict;
use warnings;

use Module::Load ();

sub create {
    my ( $class, $type, @args ) = @_;

    my $x_package = "${class}::$type";

    if (!$x_package->can('new')) {
        Module::Load::load($x_package);
    }

    return $x_package->new(@args);
}

1;
