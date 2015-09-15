use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Algorithm::CP::IZ') };

# Add
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    my $v3 = $iz->Add($v1, $v2);

    $v1->eq(3);
    $v2->eq(5);
    is($v3->value, 8);
}

# Add
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Add(9, $v1);

    $v1->eq(3);
    is($v2->value, 12);
}

# Add
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->Add($v1, 2);

    $v1->eq(3);
    is($v2->value, 5);
}

# Add
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->Add(123, 456);

    is($v1->value, 579);
}
