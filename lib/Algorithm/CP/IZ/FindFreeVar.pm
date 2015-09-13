package Algorithm::CP::IZ::FindFreeVar;

sub default {
}

sub wrap {
    my ($func, $array) = @_;

    return sub {
	return $func($array);
    }
}

1;
