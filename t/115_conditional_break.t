#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/breakpoint.pl');

command_is(['breakpoint_set', '-t', 'line', '-f', 'file://t/scripts/breakpoint.pl', '-n', 10], {
    state       => 'enabled',
    id          => 0,
});

command_is(['breakpoint_set', '-t', 'conditional', '-f', 'file://t/scripts/breakpoint.pl', '-n', 4, '--', encode_base64('should_break()')], {
    state       => 'enabled',
    id          => 1,
});

breakpoint_list_is([
    {
        id          => 0,
        type        => 'line',
        state       => 'enabled',
        filename    => abs_uri('t/scripts/breakpoint.pl'),
        lineno      => '10',
        expression  => '',
    },
    {
        id          => 1,
        type        => 'line',
        state       => 'enabled',
        filename    => abs_uri('t/scripts/breakpoint.pl'),
        lineno      => '4',
        expression  => 'should_break()',
    },
]);

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
    filename    => undef,
    lineno      => undef,
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/breakpoint.pl'),
            where       => 'main',
            lineno      => '4',
        },
    ],
});

command_is(['eval', encode_base64('$i')],{
    command => 'eval',
    result  => {
        type        => 'int',
        value       => '10',
    },
});

done_testing();
