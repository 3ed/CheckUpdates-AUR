#!perl -T
use v5.16;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CheckUpdates::AUR' ) || print "Bail out!\n";
}

diag( "Testing CheckUpdates::AUR $CheckUpdates::AUR::VERSION, Perl $], $^X" );
