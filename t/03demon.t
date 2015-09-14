use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('Algorithm::CP::IZ') };

# event_all_known
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);

    my $fire = '';

    sub handler1 {
	my ($array, $ext) = @_;

	is($v1->value, 5);
	is($v2->value, 7);
	$fire = $ext;

	return 1;
    }

    $iz->event_all_known([$v1, $v2], \&handler1, "abc");

    $v1->eq(5);
    is($fire, '');

    $v2->eq(7);
    is($fire, 'abc');
}

# event_known
{
    my $iz = Algorithm::CP::IZ->new();
    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 10);

    my $fire = '';
    my $handler_value = 99;
    my $handler_index = 99;
    my $var_value = 99;

    sub handler2 {
	my ($val, $index, $array, $ext) = @_;

	$handler_value = $val;
	$handler_index = $index;
	$var_value = $array->[$index]->value;

	$fire = $ext;
	
	return 1;
    }

    $iz->event_known([$v1, $v2], \&handler2, "abc");

    $v1->eq(5);
    is($fire, 'abc');
    is($handler_value, 5);
    is($handler_index, 0);
    is($var_value, 5);

    $v2->eq(7);
    is($fire, 'abc');
    is($handler_value, 7);
    is($handler_index, 1);
    is($var_value, 7);
}
