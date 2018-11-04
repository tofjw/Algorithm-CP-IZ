use strict;
use warnings;

use Test::More tests => 23;
BEGIN { use_ok('Algorithm::CP::IZ') };
BEGIN { use_ok('Algorithm::CP::IZ::ValueSelector') };

use Algorithm::CP::IZ qw(:value_selector);


{
    my $iz = Algorithm::CP::IZ->new;
    my $v = $iz->create_int(0, 2);

    my $vs = $iz->get_value_selector(CS_VALUE_SELECTOR_MIN_TO_MAX);
    my $vsi = $vs->init(0, [$v]);

    my ($meth, $val);

    ($meth, $val) = $vsi->next; # 0
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 0);

    ($meth, $val) = $vsi->next; # 1
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 1);

    ($meth, $val) = $vsi->next; # 2
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 2);

    ok(!defined($vsi->next));
}

{
    my $iz = Algorithm::CP::IZ->new;
    my $v = $iz->create_int(0, 2);

    my $vs = $iz->get_value_selector(CS_VALUE_SELECTOR_MAX_TO_MIN);
    my $vsi = $vs->init(0, [$v]);

    my ($meth, $val);

    ($meth, $val) = $vsi->next; # 2
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 2);

    ($meth, $val) = $vsi->next; # 1
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 1);

    ($meth, $val) = $vsi->next; # 0
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 0);

    ok(!defined($vsi->next));

    # twice
    $vsi = $vs->init(0, [$v]);

    ($meth, $val) = $vsi->next; # 2
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 2);

    ($meth, $val) = $vsi->next; # 1
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 1);

    ($meth, $val) = $vsi->next; # 0
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 0);

    ok(!defined($vsi->next));
}

