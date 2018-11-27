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

    package TestObj;
    sub new {
	my $class = shift;
	bless {}, $class;
    }

    sub search_start {
	my $self = shift;
	my $array = shift;
	print STDERR "search start!: $array\n";
    }

    sub search_end {
	my $self = shift;
	my $array = shift;
	print STDERR "search end!: $array\n";
    }
    
    package main;
    my $obj = TestObj->new;
    my $sn = $iz->create_search_notify($obj);
    print STDERR "perl obj = $obj, sn = $sn\n";
    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_MIN_TO_MAX);

    # cannot solve by MaxFail
    $iz->save_context;
    my $rc1 = $iz->search([$s, $e, $n, $d, $m, $o, $r, $y],
			  {
			      ValueSelectors =>
				  [map { $vs } 1..8],
				  MaxFail => 1000,
			      Notify => $sn,
			  });
    is($rc1, 1);
    $iz->restore_context;
    
}
