package t::X;

use parent qw( X::Tiny );

#----------------------------------------------------------------------

package t::X::Generic;

use parent qw( X::Tiny::Base );

#----------------------------------------------------------------------

package t::X::Tiny;

sub foo {
    my $x = "" . t::X->create('Generic', 'Bad!');

    print $x;
}

foo();
