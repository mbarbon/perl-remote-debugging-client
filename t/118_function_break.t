#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/function_breakpoint.pl');

command_is(['breakpoint_set', '-t', 'call', '-m', 'main::sub_break'], {
    state       => 'enabled',
    id          => 0, # this is wrong
});

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/function_breakpoint.pl'),
            where       => 'main::sub_break',
            lineno      => '10',
        },
    ],
});

done_testing();
