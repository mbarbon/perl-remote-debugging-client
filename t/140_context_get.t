#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/variables.pl');

send_command('run');

command_is(['context_get'], {
    command => 'context_get',
    values  => [
        {
            name        => '$DB::single',
            fullname    => '$DB::single',
            type        => 'int',
            constant    => '0',
            children    => '0',
            value       => '0',
        },
        {
            name        => '$foo',
            fullname    => '$foo',
            type        => 'int',
            constant    => '0',
            children    => '0',
            value       => '123',
        },
        {
            name        => '%foo',
            fullname    => '%foo',
            type        => 'HASH',
            constant    => '0',
            children    => '1',
            numchildren => '3',
            value       => undef,
            childs      => [],
        },
        {
            name        => '@foo',
            fullname    => '@foo',
            type        => 'ARRAY',
            constant    => '0',
            children    => '1',
            numchildren => '3',
            value       => undef,
            childs      => [],
        },
    ],
});

done_testing();
