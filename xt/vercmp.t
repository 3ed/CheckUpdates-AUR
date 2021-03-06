#!perl
use 5.022;
use strict;
use warnings;
use Test::More;

use OS::CheckUpdates::AUR;
use Try::Tiny;

unless ($ENV{TEST_AUTHOR_CHECKUPDATE}) {
    plan skip_all => 'Author test. (TEST_AUTHOR_CHECKUPDATE=1 to run)';
}


plan tests => 2;


my $cua = OS::CheckUpdates::AUR->new_lazy('packages' => []);

sub test_try {
	my $a = shift || undef;
	my $b = shift || undef;
	my $out;

	try   { $out = $cua->vercmp($a, $b) }
	catch { return undef };

	return $out
}

subtest "varcmp good data test" => sub {
	plan tests => 3;

	is(test_try('0.23.a', '1.7b71'), '-1', '0.23.a < 1.7b71');
	is(test_try('7.14bc', '2.79z' ), '1',  '7.14bc > 2.79z');
	is(test_try('4.123',  '4.123' ), '0',  '4.123  = 4.123');
};

subtest "vercmp bad data test" => sub {
	plan tests => 3;

	ok(! test_try('1.27', undef), 'die if: 1.27  <=> undef');
	ok(! test_try(undef, '1.27'), 'die if: undef <=> 1.27');
	ok(! test_try(undef, undef),  'die if: undef <=> undef');
}
