#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/stack.pl');

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 7,
        },
    ],
});

send_command('run')
    for 1 .. 6;

command_is(['stack_get'], {
    frames => [
        (map +{
            level       => $_,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main::fact',
            lineno      => 4,
        }, 0 .. 4),
        {
            level       => 5,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 9,
        },
    ],
});

send_command('run');

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 13,
        },
    ],
});

send_command('run');

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'eval {...}',
            lineno      => 16,
        },
        {
            level       => 1,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 13,
        },
    ],
});

send_command('run');

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'eval',
            # filename is tested below
            where       => "eval '...'",
            lineno      => 3,
        },
        {
            level       => 1,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'eval {...}',
            lineno      => 16,
        },
        {
            level       => 2,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 13,
        },
    ],
});

my $eval_frames = send_command('stack_get');

like($eval_frames->frames->[0]->filename, qr{^dbgp://perl/[^/]+/\d+/0/%28eval%20\d+%29});

send_command('run');

command_is(['stack_get'], {
    frames => [
        {
            level       => 0,
            type        => 'file',
            filename    => abs_uri('t/scripts/break.pm'),
            where       => "require 't/scripts/break.pm'",
            lineno      => 5,
        },
        {
            level       => 1,
            type        => 'file',
            filename    => abs_uri('t/scripts/stack.pl'),
            where       => 'main',
            lineno      => 25,
        },
    ],
});

done_testing();
