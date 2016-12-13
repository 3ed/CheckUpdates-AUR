#!perl -T
use 5.022;
use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_AUTHOR_CHECKUPDATE}) {
    plan skip_all => 'Author test. (TEST_AUTHOR_CHECKUPDATE=1 to run)';
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
