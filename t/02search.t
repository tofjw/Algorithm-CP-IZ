use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Algorithm::CP::IZ') };

{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(0, 10);
    $iz->search([$v]);

    is($v->min, 0);
    is($v->max, 0);
    is($v->value, 0);
    is($v->nb_elements, 1);
}

{
    my $iz = Algorithm::CP::IZ->new();

    my $func = sub {
	my $array = shift;
	my $n = scalar @$array;

	for my $i (0..$n-1) {
	    return $i if ($array->[$i]->is_free);
	}

	return -1;
    };

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);
    $iz->search_test([$v1, $v2], $func);

    print STDERR "v1 = ", $v1->value, "\n";
    print STDERR "v2 = ", $v2->value, "\n";

    is($v1->min, 0);
    is($v1->max, 0);
    is($v1->value, 0);
    is($v1->nb_elements, 1);
}
