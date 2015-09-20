use strict;
use warnings;

use Test::More tests => 24;
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

# default search
{
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);
    $iz->search([$v1, $v2]);

    print STDERR "v1 = ", $v1->value, "\n";
    print STDERR "v2 = ", $v2->value, "\n";

    is($v1->min, 0);
    is($v1->max, 0);
    is($v1->value, 0);
    is($v1->nb_elements, 1);
}

# default search (use Default)
{
    use Algorithm::CP::IZ::FindFreeVar;
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);
    $iz->search([$v1, $v2],
		{ FindFreeVar => Algorithm::CP::IZ::FindFreeVar::Default, }
	);

    is($v1->min, 0);
    is($v1->max, 0);
    is($v1->value, 0);
    is($v1->nb_elements, 1);
}

# default search (use NbElements)
{
    use Algorithm::CP::IZ::FindFreeVar;
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 5);
    $iz->AllNeq([$v1, $v2]);
    $iz->search([$v1, $v2],
		{ FindFreeVar => Algorithm::CP::IZ::FindFreeVar::NbElements, }
	);

    # v2 must be found first.
    is($v1->min, 1);
    is($v1->max, 1);
    is($v1->value, 1);
    is($v1->nb_elements, 1);
}

# search with FindFreeVar
{
    my $iz = Algorithm::CP::IZ->new();

    my $func_used = 0;

    my $func = sub {
	my $array = shift;
	my $n = scalar @$array;

	for my $i (0..$n-1) {
	    return $i if ($array->[$i]->is_free);
	}

	$func_used = 1;

	return -1;
    };

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);
    $iz->AllNeq([$v1, $v2]);
    $iz->search([$v1, $v2],
		{ FindFreeVar => $func, }
	);

    is($func_used, 1);
    is($v1->min, 0);
    is($v1->max, 0);
    is($v1->value, 0);
    is($v1->nb_elements, 1);
}

# test MaxFail uinsg send more money
{
  my $iz = Algorithm::CP::IZ->new();
  my $s = $iz->create_int(1, 9);
  my $e = $iz->create_int(0, 9);
  my $n = $iz->create_int(0, 9);
  my $d = $iz->create_int(0, 9);
  my $m = $iz->create_int(1, 9);
  my $o = $iz->create_int(0, 9);
  my $r = $iz->create_int(0, 9);
  my $y = $iz->create_int(0, 9);

  $iz->AllNeq([$s, $e, $n, $d, $m, $o, $r, $y]);

  my $v1 = $iz->ScalProd([$s, $e, $n, $d], [1000, 100, 10, 1]);
  my $v2 = $iz->ScalProd([$m, $o, $r, $e], [1000, 100, 10, 1]);
  my $v3 = $iz->ScalProd([$m, $o, $n, $e, $y], [10000, 1000, 100, 10, 1]);
  my $v4 = $iz->Add($v1, $v2);
  $v3->Eq($v4);

  $iz->save_context;
  my $rc1 = $iz->search([$s, $e, $n, $d, $m, $o, $r, $y],
			{ MaxFail => 1});
  is($rc1, 0);

  $iz->restore_context;

  my $rc = $iz->search([$s, $e, $n, $d, $m, $o, $r, $y],
		      { MaxFail => 10000});
  is($rc, 1);
}

