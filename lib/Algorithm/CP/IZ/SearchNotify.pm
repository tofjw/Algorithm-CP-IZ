package Algorithm::CP::IZ::SearchNotify;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {
    };

    bless $self, $class;

    my $ptr = &Algorithm::CP::IZ::cs_createSearchNotify($self);
    $self->{_ptr} = $ptr;
    
    return $self;
}

DESTROY {
    my $self = shift;
    Algorithm::CP::IZ::cs_freeSearchNotify($self->{_ptr});
}

1;
