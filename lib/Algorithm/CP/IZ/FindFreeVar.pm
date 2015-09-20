package Algorithm::CP::IZ::FindFreeVar;

use constant {
    Default => 0,
    NbElements => 1,
    NbElementsMin => 2,
};

sub wrap {
    my ($func, $array) = @_;

    return sub {
	return $func($array);
    }
}

1;
