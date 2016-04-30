my $i = 0;

for (1 .. 5) {
    $i += $_;
}
# non brekeable line
sub_break();

sub should_break {
    return $i > 9
}

sub sub_break {
    $i = 0;
}
