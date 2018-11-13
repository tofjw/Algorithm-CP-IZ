package Algorithm::CP::IZ::NoGoodSet;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

use Algorithm::CP::IZ;
use Algorithm::CP::IZ::RefVarArray;

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

sub nb_no_goods {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getNbNoGoods($self->{_ngs});
}

DESTROY {
}

1;
