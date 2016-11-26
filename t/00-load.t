#!perl -T
use 5.022;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OS::CheckUpdates::AUR' ) || print "Bail out!\n";
}

diag( "Testing OS::CheckUpdates::AUR $OS::CheckUpdates::AUR::VERSION, Perl $], $^X" );
