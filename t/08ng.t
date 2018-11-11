use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Algorithm::CP::IZ') };
BEGIN { use_ok('Algorithm::CP::IZ::NoGoodSet') };

if (1) {
SKIP: {
    my $iz = Algorithm::CP::IZ->new;
    skip "old iZ", 7
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);
		
    my $v = $iz->create_int(0, 2);

    package TestNG;
    sub new {
	my $class = shift;
	bless {}, $class;
    }   

    package main;

    my $obj = TestNG->new;
    print STDERR "******** 1\n";
    $iz->create_no_good_set([$v], sub { $obj->prefilter(@_); },
			    100, $obj);

    print STDERR "******** 2\n";
    ok(1);
}
}
else {
    ok(1);
}
