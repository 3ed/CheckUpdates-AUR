#!perl -T
use v5.16;
use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_AUTHOR_CHECKUPDATE}) {
    plan skip_all => 'Author test. (TEST_AUTHOR_CHECKUPDATE=1 to run)';
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();
