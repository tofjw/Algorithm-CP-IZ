use strict;
use warnings;

use Test::More tests => 26;
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

{
    package TestVS;
    sub new {
	my $class = shift;
	my ($index, $v) = @_;

	my $self = {
	    _pos => 0,
	};
	bless $self, $class;
    }

    sub next {
	my $self = shift;
	my ($v, $index) = @_;

	my $pos = $self->{_pos};
	my $domain = $v->domain;
	return if ($pos >= @$domain);

	my @ret = (Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ, $domain->[$pos]);
	$self->{_pos} = $pos++;

	return @ret;
    }

    sub DESTROY {
    }

    package main;
}

if (1) {

    use Data::Dumper;
    my $obj = Algorithm::CP::IZ::ValueSelector::Simple->new("TestVS");
    
    my $iz = Algorithm::CP::IZ->new;
    my $v = $iz->create_int(0, 2);
    # my $vsi = $obj->init(0, [$v]);
    # print $vsi->next;
}

if (1) {
    my $iz = Algorithm::CP::IZ->new();

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 5);
    $iz->AllNeq([$v1, $v2]);

    my $vs = Algorithm::CP::IZ::ValueSelector::Simple->new("TestVS");
    $vs->prepare(0);
    $vs->prepare(1);
    my $label = $iz->save_context();
    print STDERR "**************** search\n";
    my $rc = $iz->search([$v1, $v2],
			 { ValueSelectors
			       => [$vs, $vs], }
	);
    print STDERR "**************** done\n";

    is($rc, 1);
    is($v1->value, 0);
    is($v2->value, 1);
}

