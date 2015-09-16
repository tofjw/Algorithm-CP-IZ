use strict;
use warnings;

use Test::More tests => 15;
BEGIN { use_ok('Algorithm::CP::IZ') };

# create
my $iz = Algorithm::CP::IZ->new();
my $v = $iz->create_int(0, 10);

# nb_elements
is($v->nb_elements, 11);

# domain
{
  my $dom = $v->domain;
  is(@$dom, 11);
  for my $i (0..9) {
    is($dom->[$i], $i);
  }
}

# neq
{
  $iz->save_context;

  $v->Neq(5);
  is(join(",", @{$v->domain}), "0,1,2,3,4,6,7,8,9,10");
  $iz->restore_context;

  my $v2 = $iz->create_int(0, 0);

  $iz->save_context;

  $v->Neq($v2);
  is(join(",", @{$v->domain}), "1,2,3,4,5,6,7,8,9,10");
  $iz->restore_context;
}

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
