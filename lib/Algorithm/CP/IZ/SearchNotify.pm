package Algorithm::CP::IZ::SearchNotify;

use strict;
use warnings;

my @method_names = qw(
    search_start
    search_end
    before_value_selection
    after_Value_selection
    enter
    leave
    found
);

sub new {
    my $class = shift;
    my $obj = shift;
    
    my $self = {
	_obj => $obj,
    };

    bless $self, $class;

    my $ptr = &Algorithm::CP::IZ::cs_createSearchNotify($self);
    $self->{_ptr} = $ptr;

    my %methods;
    for my $m (@method_names) {
	if ($obj->can($m)) {
	    $methods{$m} = sub { $obj->$m(@_) };
	    my $xs_sub = "Algorithm::CP::IZ::searchNotify_set_$m";
	    no strict "refs";
	    &$xs_sub($ptr);
	}
    }
    
    $self->{_methods} = \%methods,
    
    return $self;
}

sub set_array {
    my $self = shift;
    my $array = shift;
    $self->{_array} = $array;
}

sub search_start {
    my $self = shift;
    my ($max_fails) = @_;
    
    &{$self->{_methods}->{search_start}}($max_fails, $self->{_array});
}

sub search_end {
    my $self = shift;
    my ($result, $nb_fails, $max_fails) = @_;
    
    &{$self->{_methods}->{search_end}}($result, $nb_fails, $max_fails, $self->{_array});
}

DESTROY {
    my $self = shift;
    Algorithm::CP::IZ::cs_freeSearchNotify($self->{_ptr});
}

1;
