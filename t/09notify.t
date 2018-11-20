use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Algorithm::CP::IZ') };

SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 1
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $sn = $iz->create_search_notify;
    ok(1);
}
