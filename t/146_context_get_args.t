#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/args.pl');

send_command('run');

command_is(['context_get', '-c', 2], {
    command => 'context_get',
    values  => [
        {
            name    => '$_[0]',
            value   => 'foo',
        },
        {
            name    => '$_[1]',
            value   => 7,
        },
    ],
});

send_command('run');

command_is(['context_get', '-c', 2], {
    command => 'context_get',
    values  => [
        {
            name    => '$_[0]',
            value   => 'bar',
        },
        {
            name    => '$_[1]',
            value   => 5,
        },
    ],
});

command_is(['context_get', '-c', 2, '-d', 1], {
    command => 'context_get',
    values  => [
        {
            name    => '$_[0]',
            value   => 'foo',
        },
        {
            name    => '$_[1]',
            value   => 7,
        },
    ],
});

command_is(['context_get', '-c', 2, '-d', 2], {
    command => 'context_get',
    values  => [
    ],
});

send_command('run');

command_is(['context_get', '-c', 2], {
    command => 'context_get',
    values  => [
    ],
});

done_testing();
