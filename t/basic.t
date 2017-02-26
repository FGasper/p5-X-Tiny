package t::X::Factory;

use parent qw( X::Tiny );

#----------------------------------------------------------------------

package t::X::Generic;

use parent qw( X::Tiny::Base );

#----------------------------------------------------------------------

package t::X::Tiny;

sub stringification {
    return "" . t::X->create('Generic', 'Bad!');
}

1;
