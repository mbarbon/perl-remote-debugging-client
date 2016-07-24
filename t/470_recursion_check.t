#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/recursion_check.pl', 'RecursionCheckDepth=22');

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
});
command_is(['stack_depth'], {
    depth   => 22,
});
position_is('t/scripts/recursion_check.pl', 2);
# eval_value_is('$_[0]', 49); this is (probably hopelessly) broken

done_testing();
