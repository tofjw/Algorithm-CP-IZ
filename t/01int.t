use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Algorithm::CP::IZ') };

my $iz = Algorithm::CP::IZ->new();
my $v = $iz->create_int(0, 10);

is($v->nb_elements, 11);

# my $l1 = $iz->save_context;
print STDERR "cs_le: ", $v->Le(5), "\n";
$iz->save_context;
print STDERR "cs_le: ", $v->Le(3), "\n";

my $v2 = $iz->create_int(-40, -2, "test");

print STDERR "name: ", $v2->name, "\n";

Algorithm::CP::IZ::RefVarArray->new([$v, $v2]);
use Data::Dumper;
print STDERR Dumper($v), Dumper($v2);


$iz->restore_all;
print STDERR "v: ", $v->min, "-", $v->max, "\n";
