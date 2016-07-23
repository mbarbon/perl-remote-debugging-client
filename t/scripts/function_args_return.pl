sub add {
    $_[0] + $_[1];
}

sub pass_add {
    &add;
}

sub context {
    $context = wantarray;
}

sub ret_scalar {
    return 42;
}

sub ret_array {
    my @dummy = (42, 43);
    return @dummy;
}

sub ret_list {
    return (42, 43);
}

sub ret_void {
    return;
}

$add_1_2 = add(1, 2);
$pass_add_2_3 = pass_add(2, 3);

$dummy = context();
$scalar_context = $context;

@dummy = context();
$list_context = $context;

context();
$void_context = $context;

$scalar_scalar = ret_scalar();
@scalar_list = ret_scalar();

$array_scalar = ret_array();
@array_list = ret_array();

$list_scalar = ret_list();
@list_list = ret_list();

$void_scalar = ret_void();
@void_list = ret_void();

$DB::single = 1;

1; # to avoid the program exiting
