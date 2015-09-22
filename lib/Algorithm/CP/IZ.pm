package Algorithm::CP::IZ;

# use 5.020001;
use 5.009000; # need Newx in XS
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

use Algorithm::CP::IZ::Int;
use Algorithm::CP::IZ::RefVarArray;
use Algorithm::CP::IZ::RefIntArray;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Algorithm::CP::IZ ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	CS_INT_MAX
	CS_INT_MIN
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	CS_INT_MAX
	CS_INT_MIN
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Algorithm::CP::IZ::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Algorithm::CP::IZ', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

my $Instances = 0;

sub new {
    my $class = shift;

    if ($Instances > 0) {
	croak __PACKAGE__ . ": another instance is working.";
    }

    Algorithm::CP::IZ::cs_init();
    $Instances++;

    bless {
	_vars => [],
	_cxt0 => [],
	_cxt => [],
	_const_vars => {},
	_backtracks => {},
    }, $class;
}

sub DESTROY {
    my $self = shift;
    my $vars = $self->{_vars};

    for my $v (@$vars) {
	$v->_invalidate($v);
    }

    Algorithm::CP::IZ::cs_end();
    $Instances--;
}

sub save_context {
    my $self = shift;
    
    Algorithm::CP::IZ::cs_saveContext();
    my $cxt = $self->{_cxt};
    push(@$cxt, []);

    return scalar(@$cxt);
}

sub restore_context {
    my $self = shift;

    my $cxt = $self->{_cxt};
    if (@$cxt == 0) {
	croak "restore_context: bottom of context stack";
    }

    Algorithm::CP::IZ::cs_restoreContext();

    # pop must be after cs_restoreContext to save cs_backtrack context.
    pop(@$cxt);
}

sub restore_context_until {
    my $self = shift;
    my $label = shift;

    my $cxt = $self->{_cxt};

    unless (1 <= $label && $label <= @$cxt) {
	croak "restore_context_until: invalid label";
    }

    while (@$cxt >= $label) {
	Algorithm::CP::IZ::cs_restoreContext();

	# pop must be after cs_restoreContext to save cs_backtrack context.
	pop(@$cxt);
    }
}

sub restore_all {
    my $self = shift;
    my $label = shift;

    Algorithm::CP::IZ::cs_restoreAll();

    # pop must be after cs_restoreContext to save cs_backtrack context.
    $self->{_cxt} = [];
}

my $Backtrack_id = 0;

sub backtrack {
    my $self = shift;
    my ($var, $index, $handler) = @_;

    my $id = $Backtrack_id++;
    my $backtrack_obj = [$var, $index, $handler];

    $self->{_backtracks}->{$id} = $backtrack_obj;

    my $h = sub {
	my $bid = shift;
	my $r = $self->{_backtracks}->{$bid};
	my $bh = $r->[2];
	&$bh($r->[0], $r->[1]);

	delete $self->{_backtracks}->{$bid};
	if (scalar keys %{$self->{_backtracks}} == 0) {
	    $self->{_backtrack_code_ref} = {};
	}
    };

    $self->{_backtrack_code_ref} = $h;

    Algorithm::CP::IZ::cs_backtrack($var->{_ptr }, $id, $h);
}

sub get_nb_fails {
    my $self = shift;

    return Algorithm::CP::IZ::cs_getNbFails();
}

sub get_nb_choice_points {
    my $self = shift;

    return Algorithm::CP::IZ::cs_getNbChoicePoints();
}

sub _create_int_from_min_max {
    my ($self, $min, $max) = @_;
    return Algorithm::CP::IZ::cs_createCSint(int($min), int($max));
}

sub _create_int_from_domain {
    my ($self, $int_array) = @_;

    my $parray = Algorithm::CP::IZ::alloc_int_array([map { int($_) } @$int_array]);
    my $ptr = Algorithm::CP::IZ::cs_createCSintFromDomain($parray, scalar @$int_array);
    Algorithm::CP::IZ::free_array($parray);

    return $ptr;
}

sub create_int {
    my $self = shift;
    my $p1 = shift;

    my $ptr;
    my $name;

    if (!ref $p1 && @_ == 0) {
	return $self->_const_var($p1);
    }
    elsif (ref $p1 && ref $p1 eq 'ARRAY') {
	$name = shift;
	$ptr = $self->_create_int_from_domain($p1);
    }
    else {
	my $min = $p1;
	my $max = shift;
	$name = shift;

	$ptr = $self->_create_int_from_min_max($min, $max);
    }

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    if (defined $name) {
	$ret->name($name);
    }

    my $vars = $self->{_vars};
    push(@$vars, $ret);

    return $ret;
}

sub search {
    my $self = shift;
    my $var_array = shift;
    my $params = shift;

    my $array = [map { $_->{_ptr } } @$var_array];

    my $max_fail = -1;
    my $find_free_var_id = 0;
    my $find_free_var_func = sub { die "search: Internal error"; };
    my $criteria_func = undef;

    if ($params->{FindFreeVar}) {
	my $ffv = $params->{FindFreeVar};

	if (ref $ffv) {
	    unless (ref $ffv eq 'CODE') {
		croak "search: FindFreeVar must be number or coderef";
	    }

	    $find_free_var_id = -1;
	    $find_free_var_func = sub {
		return &$ffv($var_array);
	    };
	}
	else {
	    $find_free_var_id = int($ffv);
	}
    }

    if ($params->{Criteria}) {
	my $cr = $params->{Criteria};
	unless (ref $cr && ref $cr eq 'CODE') {
	    croak "search: Criteria must be coderef";
	}

	$criteria_func = $cr;
    }

    if ($params->{MaxFail}) {
	$max_fail = int($params->{MaxFail});
    }

    if ($criteria_func) {
	return Algorithm::CP::IZ::cs_searchCriteria($array,
						    $find_free_var_id,
						    $find_free_var_func,
						    $criteria_func,
						    $max_fail);
    }
    else {
 	return Algorithm::CP::IZ::cs_search($array,
					    $find_free_var_id,
					    $find_free_var_func,
					    $max_fail);
   }
}

sub find_all {
    my $self = shift;
    my $var_array = shift;
    my $found_func = shift;
    my $params = shift;

    unless (ref $found_func eq 'CODE') {
	croak "find_all: usage: find_all([vars], &callback_func, {params})";
    }

    my $array = [map { $_->{_ptr } } @$var_array];

    my $find_free_var_id = 0;
    my $find_free_var_func = sub { die "find_all: Internal error"; };

    if ($params->{FindFreeVar}) {
	my $ffv = $params->{FindFreeVar};

	if (ref $ffv) {
	    unless (ref $ffv eq 'CODE') {
		croak "find_all: FindFreeVar must be number or coderef";
	    }

	    $find_free_var_id = -1;
	    $find_free_var_func = sub {
		return &$ffv($var_array);
	    };
	}
	else {
	    $find_free_var_id = int($ffv);
	}
    }

    my $call_back = sub {
	&$found_func($var_array);
    };

    return Algorithm::CP::IZ::cs_findAll($array,
					 $find_free_var_id,
					 $find_free_var_func,
					 $call_back);
}

sub _push_object {
    my $self = shift;
    my $obj = shift;

    my $cxt = $self->{_cxt};
    my $cur_cxt = $self->{_cxt0};

    if (scalar @$cxt > 0) {
	$cur_cxt = $cxt->[(scalar @$cxt) - 1];
    }

    push(@$cur_cxt, $obj);
}

sub _create_registered_var_array {
    my $self = shift;
    my $var_array = shift;;

    my $parray = Algorithm::CP::IZ::RefVarArray->new($var_array);
    $self->_push_object($parray);

    return $parray;
}

sub _create_registered_int_array {
    my $self = shift;
    my $int_array = shift;;

    my $parray = Algorithm::CP::IZ::RefIntArray->new($int_array);
    $self->_push_object($parray);

    return $parray;
}

sub _const_var {
    my $self = shift;
    my $val = shift;

    my $hash = $self->{_const_vars};

    return $hash->{$val} if (exists($hash->{$val}));

    my $v = $self->create_int($val, $val);
    $hash->{$val} = $v;

    return $v;
}

#####################################################
# Demon
#####################################################

sub event_all_known {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	return &$handler($var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventAllKnown($$parray, scalar(@$var_array), $h);
}

sub event_known {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	my ($val, $index) = @_;
	return &$handler($val, $index, $var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventKnown($$parray, scalar(@$var_array), $h);
}

sub event_new_min {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	my ($index, $old_min) = @_;
	return &$handler($var_array->[$index], $index, $old_min, $var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventNewMin($$parray, scalar(@$var_array), $h);
}

sub event_new_max {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	my ($index, $old_min) = @_;
	return &$handler($var_array->[$index], $index, $old_min, $var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventNewMax($$parray, scalar(@$var_array), $h);
}

sub event_neq {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	my ($index, $val) = @_;
	return &$handler($var_array->[$index], $index, $val, $var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventNeq($$parray, scalar(@$var_array), $h);
}

#####################################################
# Global constraints
#####################################################

sub _register_variable {
    my ($self, $var) = @_;

    my $vars = $self->{_vars};
    push(@$vars, $var);
}

sub _Add_fallback {
    my $v = shift;
    my $N = 10;

    if (@$v == 1) {
	return $v;
    }
    elsif (@$v == 2) {
	return Algorithm::CP::IZ::cs_Add(@$v);
    }
    elsif (@$v <= $N) {
	my $n = scalar @$v;
	no strict "refs";
	my $xs = "Algorithm::CP::IZ::cs_VAdd$n";
	return &$xs(@$v);
    }

    my @ptrs;
    my @rest = @$v;
    for my $i (1..$N) {
	my $p = shift @rest;
	push(@ptrs, $p);
    }


    my $xs = "Algorithm::CP::IZ::cs_VAdd$N";
    no strict "refs";
    my $part_add = &$xs(@ptrs);

    push(@rest, $part_add);

    return _Add_fallback(\@rest);
}

sub Add {
    my $self = shift;
    my @params = @_;

    if (@params < 1) {
	croak 'usage: $iz->Add(v1, v2, ...)';
    }
    if (@params == 1) {
	return $params[0];
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;
    my $ptr;

    if (@params == 2) {
 	$ptr = Algorithm::CP::IZ::cs_Add(map{$_->{_ptr}} @v);
    }
    elsif (3 <= @params && @params <= 10) {
	my $n = scalar @params;
	no strict "refs";
	my $xs = "Algorithm::CP::IZ::cs_VAdd$n";
	$ptr = &$xs(map{$_->{_ptr}} @v);
    }
    else {
	$ptr = _Add_fallback([map {$_->{_ptr}} @v]);
    }

    my $ret = Algorithm::CP::IZ::Int->new($ptr);
    $self->_register_variable($ret);

    return $ret;
}

sub ScalProd {
    my $self = shift;
    my $vars = shift;
    my $coeffs = shift;

    if (@$coeffs != @$vars) {
	croak 'usage: $iz->ScalProd([ceoffs], [vars])';
    }

    @$vars = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$vars;

    my $p1 = $self->_create_registered_var_array($vars);
    my $p2 = $self->_create_registered_int_array($coeffs);
    my $n = @$coeffs;

    my $ptr = Algorithm::CP::IZ::cs_ScalProd($$p1, $$p2, $n);
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub AllNeq {
    my $self = shift;
    my $var_array = shift;;

    my $parray = $self->_create_registered_var_array($var_array);

    return Algorithm::CP::IZ::cs_AllNeq($$parray, scalar(@$var_array));
}

1;
__END__

=head1 NAME

Algorithm::CP::IZ - Perl interface for iZ-C library

=head1 SYNOPSIS

  use Algorithm::CP::IZ;

  my $iz = Algorithm::CP::IZ->new();

  my $v1 = $iz->create_int(1, 9);
  my $v2 = $iz->create_int(1, 9);
  $iz->Add($v1, $v2)->Eq(12);
  my $rc = $iz->search([$v1, $v2]);

  if ($rc) {
    print "ok\n";
    print "v1 = ", $v1->value, "\n";
    print "v2 = ", $v2->value, "\n";
  }
  else {
    print "fail\n";
  }

=head1 DESCRIPTION

Algorithm::CP::IZ is a simple interface of iZ-C constraint programming library.

Functions declared in iz.h are mapped to:

=over 2

=item methods of Algorithm::CP::IZ

initialize, variable constructor, most of constraints
and search related functions

=item methods of Algorithm::CP::IZ::Int

accessors of variable attributes and some constraints

=back

=head2 SIMPLE CASE

In most simple case, this library will be used like following steps:

  # initialize
  use Algorithm::CP::IZ;
  my $iz = Algorithm::CP::IZ->new();

  # construct variables
  my $v1 = $iz->create_int(1, 9);
  my $v2 = $iz->create_int(1, 9);

  # add constraints ("v1 + v2 = 12" in this case)
  $iz->Add($v1, $v2)->Eq(12);

  # search solution
  my $rc = $iz->search([$v1, $v2]);

  # you may get "v1 = 3, v2 = 9"
  print "v1 = $v1, v2 = $v2\n";

=head1 CONSTRUCTOR

=head1 METHODS

=head1 SEE ALSO

L<Algorithm::CP::IZ::Int>
L<Algorithm::CP::IZ::FindFreeVar>

=head1 AUTHOR

Toshimitsu FUJIWARA, E<lt>tttfjw at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Toshimitsu FUJIWARA

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
