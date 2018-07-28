use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Algorithm::CP::IZ') };

{

    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;

    eval {
	my $v = $iz->create_int([]);
	$err = 0;
    };
    my $msg = $@;
    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}

{

    my $iz =  Algorithm::CP::IZ->new();
    my $err = 1;

    eval {
	$iz->create_int(10, -10);
	$err = 0;
    };
    my $msg = $@;

    is($err, 1);
    ok($msg =~ /^Algorithm::CP::IZ:/);
}
