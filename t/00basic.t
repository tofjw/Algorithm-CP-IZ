use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Algorithm::CP::IZ') };

my $iz = Algorithm::CP::IZ->new();
my $v1 = $iz->create_int(0, 10);


{
    my $a = $iz->save_context;
    print STDERR "save_context: $a\n";

    my $b = $iz->save_context;
    print STDERR "save_context: $b\n";

    $iz->restore_context;
    $iz->restore_context;
}


$iz = undef;
print STDERR $v1;

