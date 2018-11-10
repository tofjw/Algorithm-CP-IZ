package Algorithm::CP::IZ::NoGoodSet;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

use Algorithm::CP::IZ;
use Algorithm::CP::IZ::RefVarArray;

sub new {
    my $class = shift;
    my ($var_array, $prefilter, $ext);

    my $parray = Algorithm::CP::IZ::RefVarArray->new($var_array);
    print STDERR "RefVarArray: parray = $parray\n";
    print STDERR sprintf("RefVarArray: parray = %p\n", $$parray);
    bless {
	_var_array => $var_array,
	_parray => $parray,
	_prefilter => $prefilter,
	_ext => $ext,
    }, $class;
}

#
# internal routines for Algorithm::CP::IZ
#

sub _init {
    my $self = shift;
    my $ptr = shift;

    $self->{_ptr} = $ptr;
}

sub _parray {
    my $self = shift;
    my $parray = $self->{_parray};
    print STDERR sprintf("_parray: %p\n", $$parray);
    return $$parray;
}

sub _id {
    my $self = shift;
    return $self->{_id};
}

sub _destroy_notify {
    my $self = shift;

    delete $self->{_ptr};

    delete $self->{_var_array};
    delete $self->{_parray};
    delete $self->{_pfilter};
    delete $self->{_ext};
}

1;
