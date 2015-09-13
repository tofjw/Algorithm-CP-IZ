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
    return Algorithm::CP::IZ::cs_createCSint($min, $max);
}

sub create_int {
    my $self = shift;
    my $p1 = shift;

    my $ptr;
    my $name;

    if (ref $p1 && ref $p1 eq 'ARRAY') {
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

sub _create_registered_var_array {
    my $self = shift;
    my $var_array = shift;;

    my $parray = Algorithm::CP::IZ::RefVarArray->new($var_array);
    my $cxt = $self->{_cxt};
    my $cur_cxt = $self->{_cxt0};

    if (scalar @$cxt > 0) {
	$cur_cxt = $cxt->[(scalar @$cxt) - 1];
    }

    push(@$cur_cxt, $parray);

    return $parray;
}

#####################################################
# Global constraints
#####################################################

sub AllNeq {
    my $self = shift;
    my $var_array = shift;;

    my $parray = $self->_create_registered_var_array($var_array);
    print STDERR "parray = $parray\n";

    return Algorithm::CP::IZ::cs_AllNeq($$parray, scalar(@$var_array));
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Algorithm::CP::IZ - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Algorithm::CP::IZ;
  blah blah blah

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

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
