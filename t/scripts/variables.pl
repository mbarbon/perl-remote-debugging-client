my $foo = 123;
my @foo = qw(1 2 3);
my %foo = (a => 1, b => 2, c => 3);

$DB::single = 1;

1; # to avoid the program terminating
