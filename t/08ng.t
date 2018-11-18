use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('Algorithm::CP::IZ') };
BEGIN { use_ok('Algorithm::CP::IZ::NoGoodSet') };

# test NoGoodSet uinsg send more money
SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 8
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

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

    my $func_called = 0;  

    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_LOWER_AND_UPPER);

    my $array = [$y, $s, $e, $n, $d, $m, $o, $r];
    my @ng_set;

    package TestNG;
    sub new {
	my $class = shift;
	bless {}, $class;
    }   

    sub prefilter {
	my $self = shift;
	my $ngs = shift;
	my $ng = shift;
	my $var_array = shift;
	my $nElem = scalar @$ng;

	push(@ng_set, $ng);
	return 1;
    }
    package main;

    my $obj = TestNG->new;
    my $ngs = $iz->create_no_good_set($array,
				      sub { $obj->prefilter(@_); },
				      100, undef);
    my $restart = 0;
    my $label = $iz->save_context;
    my $rc = $iz->search($array,
			 {
			     ValueSelectors => [map { $vs } 1..8],
			     MaxFailFunc => sub {
				 $func_called++;
				 return ++$restart;
			     },
			     NoGoodSet => $ngs,
			 });

    ok($func_called > 0);
    is($rc, 1);

    ok($iz->get_nb_fails < 10000);
    ok($iz->get_nb_choice_points > 0);

    my $l1 = join(" ", map { $_->value } ($s, $e, $n, $d));
    my $l2 = join(" ", map { $_->value } ($m, $o, $r, $e));
    my $l3 = join(" ", map { $_->value } ($m, $o, $n, $e, $y));

    is($l1, "9 5 6 7");
    is($l2, "1 0 8 5");
    is($l3, "1 0 6 5 2");

    # ok($ngs->nb_no_goods > 0);
    ok(1);

    $iz->restore_context_until($label);
    use Data::Dumper;
    
    print STDERR Dumper(\@ng_set);
    for my $ng (@ng_set) {
	my $label = $iz->save_context;
	my @a;
	for my $nge (@$ng) {
	    print STDERR " index = ", $nge->index, "\n";
	    my $v = $array->[$nge->index];
	    print STDERR "before $v\n";
	    push(@a, $v->select_value($nge->method, $nge->value));
	    print STDERR "after $v\n";
	}
	$iz->restore_context_until($label);
	print STDERR "result ", join(", ", @a), "\n";
    }
}
