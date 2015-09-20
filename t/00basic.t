use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Algorithm::CP::IZ') };

my $iz = Algorithm::CP::IZ->new();
my $v1 = $iz->create_int(0, 10);


{
    my $a = $iz->save_context;
    my $b = $iz->save_context;

    $iz->restore_context;
    $iz->restore_context;

    my $err = 1;
    eval {
        $iz->restore_context;
	$err = 0;
    };

    is($err, 1);
}

# duplicated instance
{
    my $err = 1;

    eval {
	my $iz2 = Algorithm::CP::IZ->new;
	$err = 0;
    };

    is($err, 1);
}

# destroy and invalidated
{
    $iz = undef;
    is(ref $v1, "Algorithm::CP::IZ::Int::InvalidInt");
}
