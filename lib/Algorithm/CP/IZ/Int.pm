package Algorithm::CP::IZ::Int;

use strict;
use warnings;

use UNIVERSAL;

use overload '""' => \&format;

sub format {
    my $self = shift;
    my @list;


    my $cur = $self->min;
    my $head = $cur;
    my $max = $self->max;

    while ($cur != $max) {
	my $next = $self->get_next_value($cur);
	if ($next != $cur + 1) {
	    if ($head == $cur) {
		push(@list, $cur);
	    }
	    else {
		push(@list, "$head..$cur");
	    }

	    $head = $next;
	}
	$cur = $next;
    }

    # $cur == $max
    if ($head == $max) {
	push(@list, $max);
    }
    else {
	push(@list, "$head..$cur");
    }

    my $vals;
    if ($self->is_instantiated) {
	$vals = $list[0];
    }
    else {
	$vals = join("", "{" . join(", ", @list) . "}");
    }

    if ($self->{_name}) {
	return $self->{_name} . ": " . $vals;
    }
    else {
	return $vals;
    }
}

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

sub get_next_value {
    my $self = shift;
    my $val = shift;

    return Algorithm::CP::IZ::cs_getNextValue($self->{_ptr}, $val + 0);
}

sub get_previous_value {
    my $self = shift;
    my $val = shift;

    return Algorithm::CP::IZ::cs_getPreviousValue($self->{_ptr}, $val + 0);
}

sub is_in {
    my $self = shift;
    my $val = shift;

    return Algorithm::CP::IZ::cs_is_in($self->{_ptr}, $val + 0);
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

sub Lt {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Lt($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_LT($self->{_ptr}, int($val + 0));
}

sub Ge {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Ge($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_GE($self->{_ptr}, int($val + 0));
}

sub Gt {
    my $self = shift;
    my $val = shift;
    if (ref $val && $val->isa(__PACKAGE__)) {
	return Algorithm::CP::IZ::cs_Gt($self->{_ptr}, $val->{_ptr});
    }

    return Algorithm::CP::IZ::cs_GT($self->{_ptr}, int($val + 0));
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
