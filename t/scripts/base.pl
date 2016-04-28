my $i = 0;

for (1 .. 5) {
    $i += $_;
}
# not breakable line
print STDOUT "STDOUT $i\n";
print STDERR "STDERR $i\n";
