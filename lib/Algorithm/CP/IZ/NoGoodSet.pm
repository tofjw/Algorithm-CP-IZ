package Algorithm::CP::IZ::NoGoodSet;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

use Algorithm::CP::IZ;
use Algorithm::CP::IZ::RefVarArray;
use Algorithm::CP::IZ::NoGood;
use Algorithm::CP::IZ::NoGoodElement;

sub new {
    my $class = shift;
    my ($var_array, $prefilter, $ext) = @_;

    my $parray = Algorithm::CP::IZ::RefVarArray->new($var_array);
    my $self = {
	_var_array => $var_array,
	_parray => $parray,
	_prefilter => $prefilter,
	_ext => $ext,
    };
    bless $self, $class;
}

sub nb_no_goods {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getNbNoGoods($self->{_ngs});
}

our $FILTER;

sub filter_no_good {
    my $self = shift;
    my $filter = shift;

    local $FILTER = $filter;
    Algorithm::CP::IZ::cs_filterNoGood($self->{_ngs});
}

#
# internal routines for Algorithm::CP::IZ
#
sub _init {
    my $self = shift;
    my $parray = shift;

    $self->{_ngs} = $parray;
}

sub _parray {
    my $self = shift;
    my $parray = $self->{_parray};
    return $parray;
}

sub _id {
    my $self = shift;
    return $self->{_id};
}

sub _prefilter {
    my $self = shift;

    my $r = &{$self->{_prefilter}}($self, $_[0],
				   $self->{_var_array}, $self->{_ext});
    return $r ? 1: 0;
}

sub _filter {
    my $self = shift;

    my $r = &$FILTER($self, $_[0],
		     $self->{_var_array}, $self->{_ext});

    print STDERR "here r = $r\n";
    return $r ? 1: 0;
}

DESTROY {
}

1;
