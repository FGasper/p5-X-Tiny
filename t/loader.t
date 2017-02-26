use strict;
use warnings;

use Test::More;
plan tests => 2;

use FindBin;
use lib "$FindBin::Bin/lib";

use MyDist::X ();

ok(
    !overload->can('StrVal'),
    'overload.pm is not loaded by default',
);

sub do_it {
    eval { die MyDist::X->create( 'BadArg', 'username', 'ha$ha' ) };

    ok(
        overload->can('StrVal'),
        'overload.pm is loaded after exception instantiation',
    );

    die if $@;
}

eval { do_it() };

my $err = $@;

my $str = "" . $err;

diag $str;
