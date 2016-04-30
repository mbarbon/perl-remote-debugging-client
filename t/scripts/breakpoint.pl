my $i = 0;

for (1 .. 5) {
    $i += $_;
}
# non brekeable line
sub should_break {
    return $i > 0
}
