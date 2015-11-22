#!/usr/bin/perl

use t::lib::Test tests => 1;

run_debugger('t/scripts/base.pl');

ok(1); # we survived
