#
# Parameter validator
#
package Algorithm::CP::IZ::ParamValidator;

use strict;
use warnings;

use base qw(Exporter);

use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(validate);

use Carp;
use vars qw(@CARP_NOT);
@CARP_NOT = qw(Algorithm::CP::IZ);

use Scalar::Util qw(looks_like_number);
use List::Util qw(first);

my $INT_CLASS = "Algorithm::CP::IZ::Int";

sub _is_int {
    my ($x) = @_;
    return looks_like_number($x);
}

sub _is_code {
    my ($x) = @_;
    return ref $x eq 'CODE';
}

sub _is_optional_var {
    my ($x) = @_;
    return 1 unless (defined($x));
    return ref $x eq $INT_CLASS;
}

sub _is_array_of_var_or_int {
    my ($x) = @_;
    use Data::Dumper;
    return 0 unless (ref $x eq 'ARRAY');

    my $bad = first {
	my $v = $_;
	my $r = ref $v;
	if ($r) {
	    $r ne $INT_CLASS;
	}
	else {
	    !looks_like_number($v);
	}
    } @$x;

    return !defined($bad);
}

my %Validator = (
    I => \&_is_int,
    C => \&_is_code,
    oV => \&_is_optional_var,
    vA => \&_is_array_of_var_or_int,
);

sub validate {
    my $params = shift;
    my $types = shift;
    my $hint = shift;

    unless (@$params == @$types) {
	local @CARP_NOT; # to report internal error
	croak __PACKAGE__ . ": n of type does not match with params.";
    }

    for my $i (0..@$params-1) {
	my $rc;

	if (ref $types->[$i] eq 'CODE') {
	    $rc = &{$types->[$i]}($params->[$i]);
	}
	else {
	    unless ($Validator{$types->[$i]}) {
		local @CARP_NOT; # to report internal error
		croak __PACKAGE__ . ": Parameter type($i) " . ($types->[$i] // "undef") . " is not defined.";
	    }

	    $rc = &{$Validator{$types->[$i]}}($params->[$i]);
	}

	unless ($rc) {
	    my ($package, $filename, $line, $subroutine, $hasargs,
		$wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);
	    $subroutine =~ /(.*)::([^:]*)$/;
	    my ($p, $s) = ($1, $2);
	    print STDERR "MSG = $p: $hint\n";
	    croak "$p: $hint";
	}
    }
}

1;
