sub bar {
    $DB::single = 1;

    1; # to avoid an early return
}

sub foo {
    $DB::single = 1;
    bar("bar", $_[1] - 2);
}

foo("foo", 7);

$DB::single = 1;

1; # to avoid the program terminating
