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

sub new {
    my $class = shift;

    Algorithm::CP::IZ::cs_init();

    bless {
	_vars => [],
	_cxt0 => [],
	_cxt => [],
	_const_vars => {},
    }, $class;
}

sub DESTROY {
    my $self = shift;
    my $vars = $self->{_vars};

    for my $v (@$vars) {
	Algorithm::CP::IZ::InvalidInt->invalidate($v);
    }

    Algorithm::CP::IZ::cs_end();
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

    pop(@$cxt);

    Algorithm::CP::IZ::cs_restoreContext();
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
	pop(@$cxt);
    }
}

sub restore_all {
    my $self = shift;
    my $label = shift;

    Algorithm::CP::IZ::cs_restoreAll();
    $self->{_cxt} = [];
}

sub _create_int_from_min_max {
    my ($self, $min, $max) = @_;
    return Algorithm::CP::IZ::cs_createCSint($min + 0, $max + 0);
}

sub _create_int_from_domain {
	my ($self, $int_array) = @_;

    my $parray = Algorithm::CP::IZ::alloc_int_array([map { $_+0 } @$int_array]);
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
    return Algorithm::CP::IZ::cs_search_preset($array, 0, -1);
}

sub search_test {
    my $self = shift;
    my $var_array = shift;
    my $params = shift;

    my $array = [map { $_->{_ptr } } @$var_array];

    my $func = sub {
	return &$params($var_array);
    };

    return Algorithm::CP::IZ::cs_search_findFreeVar($array, $func, -1);
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

sub Add {
    my $self = shift;
    my @params = @_;

    if (@params != 2) {
	croak 'usage: $iz->Add(v1, v2)';
    }

    my @v = map { ref $_ ? $_ : $self->_const_var($_ + 0) } @params;
    my $ptr = Algorithm::CP::IZ::cs_Add($v[0]->{_ptr}, $v[1]->{_ptr});
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    my $vars = $self->{_vars};
    push(@$vars, $ret);

    return $ret;
}

sub ScalProd {
    my $self = shift;
    my $vars = shift;
    my $coeffs = shift;

    if (@$coeffs != @$vars) {
	croak 'usage: $iz->ScalProd([ceoffs], [vars])';
    }

    @$vars = map { ref $_ ? $_ : $self->_const_var($_ + 0) } @$vars;

    my $p1 = $self->_create_registered_var_array($vars);
    my $p2 = $self->_create_registered_int_array($coeffs);
    my $n = @$coeffs;

    my $ptr = Algorithm::CP::IZ::cs_ScalProd($$p1, $$p2, $n);
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    my $myvars = $self->{_vars};
    push(@$myvars, $ret);

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
# Below is stub documentation for your module. You'd better edit it!

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
    print "ng\n";
  }

=head1 DESCRIPTION

Stub documentation for Algorithm::CP::IZ, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head2 Exportable constants

  CS_ERR_GETVALUE
  CS_ERR_NONE
  CS_INT_MAX
  CS_INT_MIN
  FALSE
  TRUE
  __izwindllexport



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

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
