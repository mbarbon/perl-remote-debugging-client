#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/base.pl');

command_is(['step_into'], {
    reason  => 'ok',
    status  => 'break',
    command => 'step_into',
}) for 1 .. 9;

command_is(['step_into'], {
    reason  => 'ok',
    status  => 'stopping',
    command => 'step_into',
});

command_is(['step_into'], {
    apperr  => 4,
    code    => 6,
    message => 'Command \'step_into\' not valid at end of run.',
    command => 'step_into',
});

done_testing();
