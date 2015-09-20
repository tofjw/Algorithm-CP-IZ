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

sub _invalidate {
    my $self = shift;
    bless $self, __PACKAGE__ . "::InvalidInt";
}

1;

__END__

=head1 NAME

Algorithm::CP::IZ::Int - Domain variable for Algorithm::CP::IZ

=head1 SYNOPSIS

  use Algorithm::CP::IZ;

  my $iz = Algorithm::CP::IZ->new();

  # create instances of Algorithm::CP::IZ::Int
  # contains domain {0..9}
  my $v1 = $iz->create_int(1, 9);
  my $v2 = $iz->create_int(1, 9);

  # add constraint
  $iz->Add($v1, $v2)->Eq(12);

  # get current status
  print $v1->nb_elements, "\n2;

  # print domain
  print "$v1\n";

=head1 DESCRIPTION

Stub documentation for Algorithm::CP::IZ, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

All constraint method returns 1 (OK) or 0 (constraint violation occured).

=head1 METHODS

=over 2

=item format

Create string representation of this variable.
('""' operator has overloaded to this method.)

=item name

Get name of this variable.

=item name(NAME)

Set name of this variable.

=item nb_elements

Returns count of values in domain.

=item min

Returns minimum value of domain.

=item max

Returns maximum value of domain.

=item value

Returns instantiated value of this variable.

If this method called for not instancited variable, exception will be thrown.

=item is_free

Returns 1 (domain has more than 1 value) or 0 (domain has 1 only value).

=item is_instantiated

Returns 1 (instantiated, it means domain has only 1 value)
or 0 (domain has more than 1 value).

=item domain

Returns array reference of domain values.

=item get_next_value(X)

Returns a value next value of X in domain. (If domain is {0, 1, 2, 3} and
X is 1, next value is 2)

X must be integer value.

=item get_previous_value

Returns a value previous value of X in domain. (If domain is {0, 1, 2, 3} and
X is 2, next value is 1)

X must be integer value.

=item is_in(X)

Returns 1 (X is in domain) or 0 (X is not in domain)

X must be integer value.

=item Eq(X)

Constraints this variable "equal to X".
X must be int or instance of Algorithm::CP::IZ::Int.

=item Neq(X)

Constraints this variable "not equal to X".
X must be int or instance of Algorithm::CP::IZ::Int.

=item Le(X)

Constraints this variable "less or equal to X".
X must be int or instance of Algorithm::CP::IZ::Int.

=item Lt(X)

Constraints this variable "less than X".
X must be int or instance of Algorithm::CP::IZ::Int.

=item Ge(X)

Constraints this variable "greater or equal to X".
X must be int or instance of Algorithm::CP::IZ::Int.

=item Gt(X)

Constraints this variable "greater than X".
X must be int or instance of Algorithm::CP::IZ::Int.

=back

=head1 SEE ALSO

L<Algorithm::CP::IZ>

=head1 AUTHOR

Toshimitsu FUJIWARA, E<lt>tttfjw at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Toshimitsu FUJIWARA

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
