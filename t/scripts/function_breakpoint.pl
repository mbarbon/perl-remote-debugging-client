package foo;

sub sub_break {
    1; # we need a line here
}

package main;

sub sub_break {
    1; # we need a line here
}

foo::sub_break();
main::sub_break();

1; # to avoid the program exiting
