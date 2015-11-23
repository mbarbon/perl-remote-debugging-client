#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/base.pl', 'Xdebug=1');

command_is(['step_into'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'step_into',
    filename    => abs_uri('t/scripts/base.pl'),
    lineno      => 1,
});

done_testing();
