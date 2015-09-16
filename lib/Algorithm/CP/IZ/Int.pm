package Algorithm::CP::IZ::Int;

use strict;
use warnings;

use UNIVERSAL;

sub new {
    my $class = shift;
    my $ptr = shift;

    bless {
	_ptr => $ptr,
    }, $class;
}

sub name {
    my $self = $_[0];
    if (@_ == 1) {
	return $self->{_name};
    }

    $self->{_name} = $_[1];
}

sub nb_elements {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getNbElements($self->{_ptr});
}

sub min {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getMin($self->{_ptr});
}

sub max {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getMax($self->{_ptr});
}

sub value {
    my $self = shift;
    return Algorithm::CP::IZ::cs_getValue($self->{_ptr});
}

sub is_free {
    my $self = shift;
    return Algorithm::CP::IZ::cs_isFree($self->{_ptr});
}

sub is_instantiated {
    my $self = shift;
    return Algorithm::CP::IZ::cs_isInstantiated($self->{_ptr});
}

sub domain {
    my $self = shift;
    my @ret;

    Algorithm::CP::IZ::cs_domain($self->{_ptr}, \@ret);

    return \@ret;
}

sub Eq {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Eq($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_EQ($self->{_ptr}, int($val + 0));
}

sub Neq {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Neq($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_NEQ($self->{_ptr}, int($val + 0));
}

sub Le {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Le($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_LE($self->{_ptr}, int($val + 0));
}

sub Ge {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Ge($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_GE($self->{_ptr}, int($val + 0));
}

sub invalidate {
    Algorithm::CP::IZ::InvalidInt->invalidate(shift);
}

package Algorithm::CP::IZ::InvalidInt;

sub invalidate {
    my $class = shift;
    my $var = shift;
    bless $var, $class;
}

1;
